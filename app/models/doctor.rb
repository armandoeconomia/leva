class Doctor < ApplicationRecord
  belongs_to :user
  belongs_to :medical_institute

  has_many :appoinments
  has_many :medical_histories
  has_many :calendars
  has_many :hours, through: :calendars

  validates :specialty, presence: true, length: { minimum: 3, maximum: 100 }
  validates :medical_registration,
            presence: true,
            uniqueness: true,
            length: { minimum: 5, maximum: 50 }
end
