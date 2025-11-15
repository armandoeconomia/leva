class Doctor < ApplicationRecord
  belongs_to :user
  belongs_to :medical_institute

  has_many :appointments
  has_many :medical_histories
  has_many :calendars
  has_many :hours, through: :calendars

  enum speciality: { cardiologia: 0, general: 1, "nutrición"=> 2}
  validates :speciality, presence: true
  validates :medical_registration,
            presence: true,
            uniqueness: true,
            length: { minimum: 5, maximum: 50 }
end
