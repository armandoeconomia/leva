# Limpieza total de registros (en orden de dependencias inversas)
Hour.destroy_all
Calendar.destroy_all
MedicalHistory.destroy_all
Appointment.destroy_all
Patient.destroy_all
Doctor.destroy_all
MedicalInstitute.destroy_all
User.destroy_all

# 1. Usuario administrador
admin = User.create!(
  email: "admin@saludapp.com",
  password: "12345678",
  name: "Admin",
  last_name: "Principal",
  phone_number: "555-0000",
  birthday: Date.new(1980, 1, 1),
  address: "Calle Central 123",
  identification: "00000001",
  gender: 0,
  admin: true
)

# 2. Centro Médico (NO usamos variable para evitar error con `name`)
MedicalInstitute.create!(
  user: admin,
  name: "Hospital Militar",
  address: "Av. Salud 456",
  phone_number: "555-1234",
  emergency_phone_number: "911",
  institute_type: 0,
  latitude: -34.6037,
  longitude: -58.3816
)

# Obtenemos el instituto recién creado SIN TRIGGER de errores
institute = MedicalInstitute.order(created_at: :desc).first

# 3. Doctores
doctors = 5.times.map do |i|
  user = User.create!(
    email: "doctor#{i}@medico.com",
    password: "12345678",
    name: "Doctor#{i}",
    last_name: "Apellido#{i}",
    phone_number: "555-10#{i}",
    birthday: Date.new(1985, 5, 5),
    address: "Calle Doctor #{i}",
    identification: "1000000#{i}",
    gender: rand(0..2),
    admin: false
  )

  Doctor.create!(
    user: user,
    medical_institute: institute,
    speciality: rand(0..2),
    medical_registration: "REG#{i.to_s.rjust(3, '0')}"
  )
end

# 4. Pacientes
patients = 10.times.map do |i|
  user = User.create!(
    email: "paciente#{i}@salud.com",
    password: "12345678",
    name: "Paciente#{i}",
    last_name: "Apellido#{i}",
    phone_number: "555-20#{i}",
    birthday: Date.new(1990, 10, 10),
    address: "Calle Paciente #{i}",
    identification: "2000000#{i}",
    gender: rand(0..2),
    admin: false
  )

  Patient.create!(
    user: user,
    blood_type: rand(0..7),
    emergency_contact: "Contacto #{i}",
    allergies: "Ninguna",
    medical_history: "Sin antecedentes",
    pathology: "Ninguna",
    medical_insurance: "Seguro General",
    marital_status: rand(0..3),
    payments: rand.round(2) * 1000
  )
end

# 5. Citas médicas
5.times do
  Appointment.create!(
    doctor: doctors.sample,
    patient: patients.sample,
    date: Date.today + rand(1..30),
    hour: Time.parse("#{rand(8..17)}:00"),
    reason_for_consultation: "Consulta general",
    status: rand(0..2)
  )
end

# 6. Historias clínicas
patients.first(5).each_with_index do |patient, i|
  MedicalHistory.create!(
    doctor: doctors.sample,
    patient: patient,
    registration_date: Date.today - rand(1..10),
    diagnosis: "Diagnóstico #{i}",
    treatment: "Tratamiento #{i}",
    prescription: "Prescripción #{i}"
  )
end

# 7. Calendarios con turnos
doctors.each do |doctor|
  (0...30).each do |offset|
    date = Date.today + offset
    calendar = Calendar.create!(doctor: doctor, date: date)

    [9, 11, 13].each do |hour|
      Hour.create!(
        calendar: calendar,
        start_time: "#{hour}:00",
        end_time: "#{hour + 1}:00"
      )
    end
  end
end

puts "✅ Seeds ejecutados correctamente 🚀"
