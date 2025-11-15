class Appointment < ApplicationRecord
  belongs_to :patient
  belongs_to :doctor

  validates :date, presence: true
  validates :hour, presence: true
  validates :reason_for_consultation, presence: true, length: { minimum: 5 }
  enum status: { pendiente: 0, completado: 1, cancelado: 2}
  validates :status, presence: true
  validates :patient, presence: true
  validates :doctor, presence: true
  validates :hour, uniqueness: { scope: [:date, :doctor_id],
                                 message: "Ya existe una cita para este doctor en esa fecha y hora"}
end
