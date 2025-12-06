require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

require "date"
require "time"
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

puts "🚨 Borrando datos previos..."

Hour.destroy_all
Calendar.destroy_all
MedicalHistory.destroy_all
Appointment.destroy_all
Patient.destroy_all
Doctor.destroy_all
MedicalInstitute.destroy_all
User.destroy_all

puts "✅ Datos anteriores eliminados."

# ==========
# HELPERS
# ==========

NOMBRES_MASCULINOS = %w[
  Juan Pedro Luis Carlos José Diego Martín Nicolás Miguel Alejandro Fernando Ricardo Andrés Javier
]

NOMBRES_FEMENINOS = %w[
  María Laura Ana Paula Daniela Sofía Lucía Carolina Valeria Gabriela Andrea Natalia Verónica
]

APELLIDOS = %w[
  Pérez García Rodríguez González Fernández López Martínez Sánchez Ramírez Díaz Herrera Romero
]

ESPECIALIDADES = [
  "Urología",
  "Clínica Médica",
  "Cardiología",
  "Ginecología",
  "Pediatría",
  "Traumatología",
  "Dermatología",
  "Neurología"
]

DIAGNOSTICOS_BASE = [
  {
    diagnosis: "Infección urinaria baja no complicada",
    treatment: "Aumento de ingesta hídrica, analgesia y antibiótico empírico.",
    prescription: "Nitrofurantoína 100 mg cada 6 horas por 5 días."
  },
  {
    diagnosis: "Hiperplasia prostática benigna sintomática",
    treatment: "Tratamiento médico inicial y control urológico periódico.",
    prescription: "Tamsulosina 0,4 mg una vez al día después de la cena."
  },
  {
    diagnosis: "Litiasis renal no complicada",
    treatment: "Hidratación abundante, analgesia y vigilancia clínica.",
    prescription: "Ibuprofeno 600 mg cada 8 horas por 3 días si dolor."
  },
  {
    diagnosis: "Cistitis recurrente",
    treatment: "Profilaxis, medidas higiénico-dietéticas y control urológico.",
    prescription: "Fosfomicina trometamol 3 g dosis única según esquema."
  },
  {
    diagnosis: "Insuficiencia renal crónica leve",
    treatment: "Control estrecho de función renal y factores de riesgo cardiovascular.",
    prescription: "Control de presión arterial, dieta hiposódica y seguimiento por nefrología."
  }
]

GRUPOS_SANGUINEOS = %w[A+ A- B+ B- AB+ AB- 0+ 0-]

ESTADOS_CIVILES = %w[soltero casado separado viudo]
SEXO_MAP = { masculino: 0, femenino: 1 }

def nombre_completo_generico(sexo: :masculino)
  nombres = sexo == :masculino ? NOMBRES_MASCULINOS : NOMBRES_FEMENINOS
  "#{nombres.sample} #{APELLIDOS.sample}"
end

def telefono_argentino
  "+54 11 #{rand(4000..5999)}-#{rand(1000..9999)}"
end

def numero_documento
  "#{rand(20_000_000..45_000_000)}"
end

def email_from_name(name, suffix)
  base = name.downcase.gsub(" ", ".").tr("áéíóúñ", "aeioun")
  "#{base}.#{suffix}@hospital-ai.test"
end

puts "🏥 Creando instituciones médicas y usuarios administradores..."

institutes_data = [
  {
    name: "Clínica Central Buenos Aires",
    address: "Av. Santa Fe 1234, Buenos Aires",
    phone_number: telefono_argentino,
    emergency_phone_number: telefono_argentino,
    institute_type: :publico,
    latitude: -34.6037,
    longitude: -58.3816
  },
  {
    name: "Sanatorio del Río",
    address: "Bv. Oroño 2200, Rosario, Santa Fe",
    phone_number: telefono_argentino,
    emergency_phone_number: telefono_argentino,
    institute_type: :privado,
    latitude: -32.9575,
    longitude: -60.6394
  },
  {
    name: "Hospital Universitario del Sur",
    address: "Av. Colón 3500, Córdoba",
    phone_number: telefono_argentino,
    emergency_phone_number: telefono_argentino,
    institute_type: :publico,
    latitude: -31.4201,
    longitude: -64.1888
  }
]

medical_institutes = []
admin_users = []

institutes_data.each_with_index do |data, index|
  admin_name = "Administrador #{index + 1} #{data[:name].split.first}"
  admin_email = email_from_name(admin_name, "admin")

  admin_user = User.create!(
    email: admin_email,
    password: "admin12345",
    password_confirmation: "admin12345",
    name: admin_name,
    last_name: "Sistema",
    phone_number: telefono_argentino,
    admin: true,
    birthday: Date.new(1980, 1, 1),
    address: data[:address],
    identification: numero_documento,
    gender: 0
  )

  institute = MedicalInstitute.create!(
    user: admin_user,
    name: data[:name],
    address: data[:address],
    phone_number: data[:phone_number],
    emergency_phone_number: data[:emergency_phone_number],
    institute_type: data[:institute_type],
    latitude: data[:latitude],
    longitude: data[:longitude]
  )

  medical_institutes << institute
  admin_users << admin_user
end

puts "✅ 3 instituciones y 3 administradores creados."

puts "👨‍⚕️ Creando doctores y 👨‍🦽 pacientes..."

doctors_by_institute = Hash.new { |h, k| h[k] = [] }
patients_by_institute = Hash.new { |h, k| h[k] = [] }
patient_institute_map = {}

medical_institutes.each_with_index do |institute, idx|
  puts "  ➤ Instituto: #{institute.name}"

  # 10 doctores por instituto
  10.times do |i|
    sexo = i.even? ? :masculino : :femenino
    nombre = nombre_completo_generico(sexo: sexo)
    email = email_from_name(nombre, "doctor#{idx + 1}_#{i + 1}")

    user = User.create!(
      email: email,
      password: "doctor123",
      password_confirmation: "doctor123",
      name: nombre.split.first,
      last_name: nombre.split.last,
      phone_number: telefono_argentino,
      admin: false,
      birthday: Date.new(rand(1965..1990), rand(1..12), rand(1..28)),
      address: institute.address,
      identification: numero_documento,
      gender: SEXO_MAP[sexo]
    )

    speciality_key = Doctor.specialities.keys.sample
    doctor = Doctor.create!(
      user: user,
      medical_institute: institute,
      speciality: speciality_key,
      medical_registration: "MP #{rand(10_000..99_999)}"
    )

    doctors_by_institute[institute] << doctor
  end

  # 10 pacientes por instituto
  10.times do |i|
    sexo = i.odd? ? :masculino : :femenino
    nombre = nombre_completo_generico(sexo: sexo)
    email = email_from_name(nombre, "paciente#{idx + 1}_#{i + 1}")

    user = User.create!(
      email: email,
      password: "paciente123",
      password_confirmation: "paciente123",
      name: nombre.split.first,
      last_name: nombre.split.last,
      phone_number: telefono_argentino,
      admin: false,
      birthday: Date.new(rand(1970..2005), rand(1..12), rand(1..28)),
      address: "Calle #{rand(1..999)}, #{institute.address}",
      identification: numero_documento,
      gender: SEXO_MAP[sexo]
    )

    paciente = Patient.create!(
      user: user,
      blood_type: rand(0...GRUPOS_SANGUINEOS.size),
      emergency_contact: "Contacto de emergencia: #{nombre_completo_generico(sexo: :masculino)} - #{telefono_argentino}",
      allergies: ["Ninguna conocida", "AINEs", "Penicilina", "Iodo"].sample,
      medical_history: "Antecedentes personales patológicos y quirúrgicos sin particularidades relevantes.",
      pathology: "Control urológico de rutina.",
      medical_insurance: ["OSDE", "Swiss Medical", "Galeno", "Medicus", "PAMI"].sample,
      marital_status: rand(0...ESTADOS_CIVILES.size),
      payments: rand(0.0..150_000.0).round(2)
    )

    patients_by_institute[institute] << paciente
    patient_institute_map[paciente] = institute
  end
end

puts "✅ Doctores y pacientes creados."

puts "📅 Creando 10 citas entre doctores y pacientes..."

appointments = []
10.times do
  institute = medical_institutes.sample
  doctor = doctors_by_institute[institute].sample
  patient = patients_by_institute[institute].sample

  start_of_month = Date.today.beginning_of_month
  end_of_month   = Date.today.end_of_month
  date = rand(start_of_month..end_of_month)

  hour_int = rand(8..16)
  hour_time = Time.parse("#{format('%02d', hour_int)}:00")

  reason = [
    "Control urológico de rutina.",
    "Síntomas urinarios bajos.",
    "Evaluación por litiasis renal.",
    "Consulta por hematuria.",
    "Dolor lumbar de origen urológico."
  ].sample

  appointment = Appointment.create!(
    patient: patient,
    doctor: doctor,
    date: date,
    hour: hour_time,
    reason_for_consultation: reason,
    status: 0
  )

  appointments << appointment
end

puts "✅ 10 citas creadas."

puts "📈 Generando citas históricas para nutrir el dashboard..."

historical_months = 5
historical_months.downto(1) do |months_ago|
  month_reference = months_ago.months.ago
  month_range = month_reference.beginning_of_month..month_reference.end_of_month
  month_total = rand(10..18)

  month_total.times do
    institute = medical_institutes.sample
    doctor = doctors_by_institute[institute].sample
    patient = patients_by_institute[institute].sample
    next unless doctor && patient

    hour_int = rand(8..17)
    hour_time = Time.parse("#{format('%02d', hour_int)}:00")

    reason = [
      "Control evolutivo de tratamiento.",
      "Consulta preventiva general.",
      "Seguimiento de laboratorio.",
      "Evaluación prequirúrgica.",
      "Chequeo periódico integral."
    ].sample

    appointment = Appointment.create!(
      patient: patient,
      doctor: doctor,
      date: rand(month_range),
      hour: hour_time,
      reason_for_consultation: reason,
      status: Appointment.statuses.keys.sample
    )

    appointments << appointment
  end

  puts "  ➤ #{month_reference.strftime('%B %Y')} • #{month_total} citas generadas."
end

puts "✅ Historial mensual adicional creado."

puts "📁 Creando historias clínicas (5 por paciente)..."

patients_by_institute.values.flatten.each do |patient|
  5.times do
    institute = patient_institute_map[patient]
    doctor = doctors_by_institute[institute].sample
    diag = DIAGNOSTICOS_BASE.sample

    MedicalHistory.create!(
      patient: patient,
      doctor: doctor,
      registration_date: Date.today - rand(10..180),
      diagnosis: diag[:diagnosis],
      treatment: diag[:treatment],
      prescription: diag[:prescription]
    )
  end
end

puts "✅ Historias clínicas creadas."

puts "🗓️ Creando calendarios y horarios disponibles para todos los doctores..."

calendar_start = Date.today
calendar_end = calendar_start + 21
slot_templates = (8..17).map do |hour|
  "#{format('%02d', hour)}:00"
end

Doctor.find_each do |doctor|
  (calendar_start..calendar_end).each do |day|
    calendar = Calendar.create!(doctor: doctor, date: day)
    daily_slots = slot_templates.sample(rand(4..slot_templates.size)).uniq.sort

    daily_slots.each do |slot|
      start_time = Time.parse(slot)
      Hour.create!(
        calendar: calendar,
        start_time: start_time,
        end_time: start_time + 1.hour
      )
    end
  end
end

puts "✅ Calendarios y horarios cargados."

puts "🎉 Seed completado:"
puts "  Usuarios:          #{User.count}"
puts "  Instituciones:     #{MedicalInstitute.count}"
puts "  Doctores:          #{Doctor.count}"
puts "  Pacientes:         #{Patient.count}"
puts "  Citas:             #{Appointment.count}"
puts "  Historias clínicas:#{MedicalHistory.count}"
puts "  Calendarios:       #{Calendar.count}"
puts "  Horas:             #{Hour.count}"
