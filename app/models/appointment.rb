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
  validate :hour_within_business_hours

  private

  def hour_within_business_hours
    return if hour.blank?

    seconds = hour.seconds_since_midnight
    earliest = 8.hours
    latest = 17.hours

    unless seconds.between?(earliest, latest)
      errors.add(:hour, "debe estar entre las 08:00 y las 17:00")
      return
    end

    unless (seconds % 1.hour).zero?
      errors.add(:hour, "debe configurarse en intervalos de 1 hora")
    end
  end
end
