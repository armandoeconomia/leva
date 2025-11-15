class Doctor < ApplicationRecord
  belongs_to :user
  belongs_to :medical_institute

  has_many :appoinments
  has_many :medical_histories
  has_many :calendars
  has_many :hours, through: :calendars
end
