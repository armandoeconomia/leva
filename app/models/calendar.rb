class Calendar < ApplicationRecord
  belongs_to :doctor
  has_many  :hours

  validates :date, presence: true
  validates :date, uniqueness: { scope: :doctor_id,
                                 message: "ya tiene un calendario creado para esta fecha" }
  validate :date_cannot_be_in_the_past

  private

  def date_cannot_be_in_the_past
    return if date.blank?

    if date < Date.today
      errors.add(:date, "no puede ser una fecha pasada")
    end
  end
end
