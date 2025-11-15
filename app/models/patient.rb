class Patient < ApplicationRecord
  belongs_to :user

  has_many :appoinments
  has_many :medical_histories
  has_many :doctors, through: :medical_histories
end
