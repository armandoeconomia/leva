module Ai
  class AssistantService
    attr_reader :conversation

    FALLBACK_MESSAGE = "No pude procesar tu solicitud en este momento. Intenta nuevamente en unos segundos.".freeze

    def self.context_for(user:, role:)
      role_name = role.to_s
      conversation = user.ai_conversations.find_by(role: role_name) || AiConversation.new(user:, role: role_name)
      new(conversation: conversation).context_snapshot
    end

    def initialize(conversation:)
      @conversation = conversation
      @user = conversation.user
    end

    def respond_to!(user_message)
      context_data = context_snapshot
      response = query_llm(user_message, context_data)
      save_response(response, context_data)
    rescue StandardError => error
      Rails.logger.error("[AI] #{error.class}: #{error.message}")
      conversation.ai_messages.create!(
        sender: :assistant,
        content: FALLBACK_MESSAGE,
        metadata: { error: error.message }
      )
      FALLBACK_MESSAGE
    end

    def context_snapshot
      data = build_context_data
      conversation.update!(context_snapshot: data) if conversation.persisted?
      data
    end

    private

    attr_reader :user

    def query_llm(user_message, context_data)
      chat = RubyLLM.chat
      chat.with_instructions(system_prompt(context_data))
      history_payload(user_message).each { |payload| chat.add_message(payload) }

      attachments = user_message.documents if user_message.documents.attached?
      chat.ask(user_prompt_for(user_message), with: attachments)
    end

    def history_payload(user_message)
      conversation.ai_messages
                  .where.not(id: user_message.id)
                  .order(created_at: :asc)
                  .last(10)
                  .map do |message|
        {
          role: message.assistant? ? :assistant : :user,
          content: message.content_with_attachments
        }
      end
    end

    def user_prompt_for(message)
      parts = []
      parts << message.content if message.content.present?

      if message.documents.attached?
        filenames = message.documents.map { |doc| doc.filename.to_s }
        parts << "El usuario adjuntó los archivos: #{filenames.join(', ')}. Analízalos y explica los hallazgos relevantes."
      end

      if message.stored_exam?
        parts << "Resume los hallazgos de estos archivos para guardarlos en el historial médico del usuario."
      end

      parts.compact.join("\n\n")
    end

    def save_response(response, context_data)
      conversation.ai_messages.create!(
        sender: :assistant,
        content: response.content.to_s,
        metadata: {
          model: response.model_id,
          input_tokens: response.input_tokens,
          output_tokens: response.output_tokens,
          raw: response.raw,
          context: context_data
        }.compact
      )
    end

    def system_prompt(context_data)
      base = <<~PROMPT
        Eres Leva Copilot, un asistente médico digital que responde únicamente en español.
        Usa un tono profesional y empático, incluye recomendaciones basadas en datos clínicos
        y aclara que no sustituyes a la valoración de un especialista. Nunca inventes información.
      PROMPT

      body = case conversation.role
             when "doctor"
               <<~PROMPT
                 Asistes a un doctor. Puedes razonar sobre diagnósticos diferenciales, tratamientos
                 y guías clínicas. Si el doctor solicita métricas de agenda, responde con los datos provistos.
                 Ofrece listados o pasos concretos cuando sea útil.
               PROMPT
             when "admin"
               <<~PROMPT
                 Eres un asistente operativo para un administrador de clínicas. Responde a solicitudes
                 como conteo de citas, pacientes o doctores usando los datos proporcionados.
                 Sé concreto y presenta cifras en listas o tablas pequeñas si corresponde.
               PROMPT
             else
               <<~PROMPT
                 Estás atendiendo a un paciente. Explica conceptos médicos de forma sencilla y da
                 recomendaciones preventivas. Si detectas señales de alarma, sugiere acudir a urgencias
                 o contactar a su médico tratante. Resume los archivos adjuntos en lenguaje claro.

                 Cuando el paciente solicite una cita, revisa la clave `disponibilidad_especialidades` del
                 contexto. Filtra las especialidades que coincidan con lo que pide, sugiere doctores y horarios,
                 y menciona el enlace `agenda_path` si está disponible para que pueda reservar.
               PROMPT
             end

      <<~PROMPT
        #{base}

        #{body}
        Datos actualizados en formato JSON:
        #{JSON.pretty_generate(context_data)}
      PROMPT
    end

    def build_context_data
      case conversation.role
      when "doctor" then doctor_context
      when "admin" then admin_context
      else patient_context
      end
    end

    def patient_context
      patient = user.patient
      return {} unless patient

      {
        perfil: {
          nombre: patient.user.name,
          apellido: patient.user.last_name,
          sangre: patient.blood_type,
          alergias: patient.allergies,
          patologia: patient.pathology,
          seguro: patient.medical_insurance
        },
        proximas_citas: patient.appointments.order(date: :asc, hour: :asc).limit(5).map do |appointment|
          {
            fecha: appointment.date,
            hora: appointment.hour&.strftime("%H:%M"),
            doctor: [appointment.doctor&.user&.name, appointment.doctor&.user&.last_name].compact.join(" "),
            especialidad: appointment.doctor&.speciality
          }
        end,
        historiales_recientes: patient.medical_histories.order(registration_date: :desc).limit(3).map do |history|
          {
            fecha: history.registration_date,
            doctor: history.doctor&.user&.name,
            diagnostico: history.diagnosis&.truncate(100),
            tratamiento: history.treatment&.truncate(120)
          }
        end,
        examenes_guardados: conversation.ai_messages.with_stored_exam.order(created_at: :desc).limit(6).map do |message|
          {
            registrado_el: message.created_at,
            notas: message.content,
            archivos: message.documents.map { |doc| doc.filename.to_s }
          }
        end,
        disponibilidad_especialidades: availability_by_speciality
      }
    end

    def doctor_context
      doctor = user.doctor
      return {} unless doctor

      today = current_date
      next_seven_days = today + 7.days

      todays_appointments = doctor.appointments.where(date: today).order(:hour)
      upcoming = doctor.appointments.where(date: today..(today + 14.days)).order(:date, :hour).limit(8)

      {
        doctor: {
          nombre: doctor.user.name,
          especialidad: doctor.speciality,
          instituto: doctor.medical_institute&.name
        },
        agenda: {
          citas_hoy: todays_appointments.count,
          detalle_hoy: todays_appointments.map do |appointment|
            {
              paciente: appointment.patient&.user&.name,
              hora: appointment.hour&.strftime("%H:%M"),
              motivo: appointment.reason_for_consultation&.truncate(80)
            }
          end,
          proximas_citas: upcoming.map do |appointment|
            {
              fecha: appointment.date,
              hora: appointment.hour&.strftime("%H:%M"),
              paciente: appointment.patient&.user&.name
            }
          end,
          citas_7_dias: doctor.appointments.where(date: today..next_seven_days).count
        },
        pacientes: {
          activos: doctor.medical_histories.select(:patient_id).distinct.count,
          vistos_30_dias: doctor.appointments.where("date >= ?", today - 30.days).select(:patient_id).distinct.count
        }
      }
    end

    def admin_context
      today = current_date
      week_range = today.beginning_of_week..today.end_of_week

      upcoming_week = (today + 7.days).beginning_of_week..(today + 7.days).end_of_week

      {
        totales: {
          usuarios: User.count,
          pacientes: Patient.count,
          doctores: Doctor.count,
          citas: Appointment.count,
          institutos: MedicalInstitute.count
        },
        operaciones: {
          citas_hoy: Appointment.where(date: today).count,
          citas_semana_actual: Appointment.where(date: week_range).count,
          citas_semana_siguiente: Appointment.where(date: upcoming_week).count
        },
        institutos_destacados: MedicalInstitute.order(:name).limit(5).map do |institute|
          {
            nombre: institute.name,
            doctores: institute.doctors.count,
            administrador: institute.user&.email
          }
        end
      }
    end

    def current_date
      Time.zone ? Time.zone.today : Date.today
    end

    def availability_by_speciality
      start_date = current_date
      end_date = start_date + 14.days

      doctors = Doctor.includes(:user, :medical_institute, calendars: :hours)
                      .where(calendars: { date: start_date..end_date })
                      .references(:calendars)

      return [] if doctors.blank?

      busy_slots = Appointment
                   .where(date: start_date..end_date)
                   .where.not(status: Appointment.statuses[:cancelado])
                   .each_with_object({}) do |appointment, hash|
                     formatted_hour = appointment.hour&.strftime("%H:%M")
                     next if formatted_hour.blank?

                     hash[[appointment.doctor_id, appointment.date, formatted_hour]] = true
                   end

      doctors_with_availability = doctors.filter_map do |doctor|
        slots = available_slots_for(doctor, start_date, end_date, busy_slots)
        next if slots.empty?

        {
          especialidad: doctor.speciality&.humanize || "General",
          doctor_id: doctor.id,
          doctor: [doctor.user.name, doctor.user.last_name].compact.join(" "),
          institucion: doctor.medical_institute&.name,
          ubicacion: doctor.medical_institute&.address,
          proximos_horarios: slots.first(5)
        }
      end

      doctors_with_availability
        .group_by { |entry| entry[:especialidad] }
        .map do |speciality, doctors_for_speciality|
          {
            especialidad: speciality,
            doctores: doctors_for_speciality.first(5)
          }
        end
    end

    def available_slots_for(doctor, start_date, end_date, busy_slots)
      relevant_calendars = doctor.calendars.select do |calendar|
        calendar.date.present? && calendar.date >= start_date && calendar.date <= end_date
      end

      slots = relevant_calendars.flat_map do |calendar|
        calendar.hours.sort_by(&:start_time).filter_map do |hour|
          formatted_hour = hour.start_time&.strftime("%H:%M")
          next if formatted_hour.blank?
          next if busy_slots[[doctor.id, calendar.date, formatted_hour]]

          {
            fecha: calendar.date,
            fecha_legible: calendar.date.strftime("%A %d %B"),
            hora: formatted_hour,
            hora_fin: hour.end_time&.strftime("%H:%M"),
            agenda_path: booking_path_for(doctor.id, calendar.date, formatted_hour)
          }
        end
      end

      slots.sort_by { |slot| [slot[:fecha], slot[:hora]] }
    end

    def booking_path_for(doctor_id, date, hour)
      Rails.application.routes.url_helpers.new_patients_appointment_path(
        doctor_id: doctor_id,
        date: date,
        hour: hour
      )
    rescue StandardError
      nil
    end
  end
end
