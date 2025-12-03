require "securerandom"
require "time"

module Ai
  class PublicAppointmentAssistant
    attr_reader :availability_snapshot

    def initialize
      @availability_snapshot = Ai::AvailabilityBuilder.new.speciality_snapshot
    end

    def respond_to(message, history: [])
      chat = RubyLLM.chat
      chat.with_instructions(system_prompt)
      sanitize_history(history).each do |entry|
        chat.add_message(entry)
      end
      prompt_message = transform_message(message)
      raw_reply = chat.ask(prompt_with_context(prompt_message, message)).content.to_s

      schedule_payloads = extract_booking_payloads(raw_reply)
      clean_reply = raw_reply.gsub(BOOKING_REGEX, "").strip

      schedule_payloads.each do |payload|
        result = schedule_from_payload(payload)
        if result[:success]
          appointment = result[:success]
          confirmation = <<~MSG
            ✅ Tu cita quedó registrada para el #{appointment.date.strftime("%d %b %Y")} a las #{appointment.hour.strftime("%H:%M")} con #{appointment.doctor.user.name} #{appointment.doctor.user.last_name}.
            Te enviaremos los detalles al correo #{appointment.patient.user.email}.
          MSG
          clean_reply = "#{clean_reply}\n\n#{confirmation}".strip
        elsif result[:error]
          clean_reply = "#{clean_reply}\n\n#{result[:error]}".strip
        end
      end

      clean_reply
    end

    private

    BOOKING_REGEX = /<BOOK_APPOINTMENT>(.*?)<\/BOOK_APPOINTMENT>/m.freeze

    def system_prompt
      <<~PROMPT
        Eres un asistente virtual de LEVA encargado exclusivamente de ofrecer información sobre
        disponibilidad de citas y coordinar reservas. Siempre respondes en español.

        - Usa únicamente los datos de disponibilidad proporcionados. Cada médico incluye un campo "opcion" que debes emplear para enumerar.
        - Siempre presenta las alternativas en listas numeradas (1., 2., 3.) mencionando doctor, especialidad, ubicación y horarios en la misma línea.
        - Cuando necesites que seleccionen un horario dentro de un mismo doctor, vuelve a enumerar los horarios disponibles empezando desde 1 para esa lista puntual.
        - Si el visitante responde solo con un número, interprétalo como la opción correspondiente de la lista numerada más reciente.
        - Si el visitante habla de otra cosa, recuérdale que solo atiendes consultas de disponibilidad.
        - No muestres ni menciones enlaces/URLs. Tu respuesta debe describir la cita y confirmar verbalmente.
        - Antes de agendar, recopila TODOS los datos del paciente según este esquema:
          * name (nombre)
          * last_name (apellido)
          * email
          * phone_number
          * city
          * gender (masculino, femenino u otro)
          * identification
          * blood_type (A+, A-, B+, B-, AB+, AB-, O+, O-)
          * emergency_contact
          * allergies (puede ser "Sin alergias reportadas")
          * medical_history (antecedentes relevantes)
          * medical_insurance (si no menciona, escribe "No especificado")
          * pathology (diagnóstico o condición principal, "No especificado" si no aplica)
          * reason_for_consultation
        - El flujo siempre es: (1) sugerir doctores disponibles y confirmar la opción elegida (doctor + hora), (2) recién entonces solicitar los datos del paciente listados arriba, aclarando que toda la información a partir de ese momento corresponde al paciente, (3) confirmar la cita.
        - Pregunta uno a uno los campos faltantes. Confirma también doctor seleccionado, fecha y hora válida.
        - Cuando dispongas de todos los datos y de un horario libre, emite exactamente un bloque:
          <BOOK_APPOINTMENT>
          {
            "name": "...",
            "last_name": "...",
            "email": "...",
            "phone_number": "...",
            "city": "...",
            "gender": "...",
            "identification": "...",
            "blood_type": "...",
            "emergency_contact": "...",
            "allergies": "...",
            "medical_history": "...",
            "medical_insurance": "...",
            "pathology": "...",
            "reason_for_consultation": "...",
            "doctor_id": 123,
            "date": "YYYY-MM-DD",
            "hour": "HH:MM"
          }
          </BOOK_APPOINTMENT>
        - Nunca incluyas texto extra dentro del bloque y utilízalo solo cuando la información este completa.
        - Después de agendar, confirma amablemente a la persona que la cita quedó registrada y ofrece más ayuda.
      PROMPT
    end

    def prompt_with_context(message, original_input = nil)
      observation = if original_input && original_input.to_s.strip != message.to_s.strip
                      %(Consulta original: "#{original_input}". Interpretación sugerida: #{message}.)
                    else
                      %(Consulta del visitante: "#{message}")
                    end

      <<~PROMPT
        Disponibilidad actual (JSON):
        #{JSON.pretty_generate(@availability_snapshot)}

        #{observation}

        Respuesta:
      PROMPT
    end

    def extract_booking_payloads(text)
      text.scan(BOOKING_REGEX).filter_map do |match|
        JSON.parse(match.first) rescue nil
      end
    end

    def schedule_from_payload(data)
      required = %w[name last_name email phone_number city gender identification blood_type emergency_contact medical_history medical_insurance pathology reason_for_consultation doctor_id date hour]
      return { error: "Necesito todos tus datos para agendar. Revisemos la información." } unless required.all? { |key| data[key].present? }

      doctor = Doctor.find_by(id: data["doctor_id"])
      return { error: "No pude encontrar a ese especialista. Por favor, selecciona uno de la lista disponible." } unless doctor

      date = Date.parse(data["date"]) rescue nil
      hour_str = data["hour"]
      hour_time = parse_hour(hour_str, date)
      return { error: "Necesito una fecha y hora válidas para bloquear la cita." } unless date && hour_time

      if Appointment.exists?(doctor_id: doctor.id, date:, hour: hour_time)
        return { error: "Ese horario recién se reservó. Elige otra opción disponible y lo confirmamos." }
      end

      appointment = nil
      ActiveRecord::Base.transaction do
        user = build_or_update_user(data)
        patient = build_or_update_patient(user, data)

        appointment = Appointment.create!(
          patient:,
          doctor:,
          date:,
          hour: hour_time,
          reason_for_consultation: data["reason_for_consultation"],
          status: :pendiente
        )
      end

      { success: appointment }
    rescue ActiveRecord::RecordInvalid => e
      { error: "No pude completar la cita porque #{e.record.errors.full_messages.to_sentence}. Corrijamos ese dato." }
    rescue StandardError => e
      Rails.logger.error("[PublicAppointmentAssistant] #{e.class}: #{e.message}")
      { error: "Tuvimos un inconveniente al agendar. Intentemos nuevamente." }
    end

    def build_or_update_user(data)
      user = User.find_or_initialize_by(email: data["email"].downcase)
      user.password ||= SecureRandom.hex(12)
      user.password_confirmation = user.password
      user.assign_attributes(
        name: data["name"],
        last_name: data["last_name"],
        phone_number: data["phone_number"],
        address: data["city"],
        gender: normalize_gender(data["gender"]),
        identification: data["identification"]
      )
      user.save!
      user
    end

    def build_or_update_patient(user, data)
      patient = user.patient || user.build_patient
      patient.assign_attributes(
        blood_type: normalize_blood_type(data["blood_type"]),
        emergency_contact: data["emergency_contact"],
        allergies: data["allergies"].presence,
        medical_history: data["medical_history"].presence,
        medical_insurance: data["medical_insurance"].presence,
        pathology: data["pathology"].presence
      )
      patient.save!
      patient
    end

    def normalize_gender(value)
      case value.to_s.strip.downcase
      when "femenino", "fem", "mujer" then :femenino
      when "masculino", "masc", "hombre" then :masculino
      else :otro
      end
    end

    def normalize_blood_type(value)
      allowed = Patient.blood_types.keys
      lookup = value.to_s.strip.upcase
      allowed.include?(lookup) ? lookup : allowed.first
    end

    def parse_hour(hour_string, date)
      return unless date && hour_string.present?

      if Time.zone
        Time.zone.parse("#{date} #{hour_string}")
      else
        Time.parse("#{date} #{hour_string}")
      end
    rescue ArgumentError
      nil
    end

    def sanitize_history(history)
      Array(history).filter_map do |entry|
        role = (entry[:role] || entry["role"]).to_s
        content = entry[:content] || entry["content"]
        next if role.blank? || content.blank?

        normalized_role = role == "assistant" ? :assistant : :user
        { role: normalized_role, content: content.to_s }
      end
    end

    def transform_message(message)
      text = message.to_s.strip
      return text if text.blank?

      if text.match?(/^\d+$/)
        "El visitante ingresó únicamente el número #{text}. Selecciona la opción #{text} de la última lista numerada disponible."
      else
        text
      end
    end
  end
end
