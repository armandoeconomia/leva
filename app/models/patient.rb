class Patient < ApplicationRecord
  belongs_to :user

  has_many :appoinments
  has_many :medical_histories
  has_many :doctors, through: :medical_histories

  enum blood_type: { "A+"=> 0, "A-"=> 1, "B+"=> 2,  "B-"=> 3, "AB+"=> 4, "AB-"=> 5, "O+"=> 6, "O-"=> 7}
  validates :blood_type, presence: true
  validates :emergency_contact, presence: true
end
