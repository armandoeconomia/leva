class Patient < ApplicationRecord
  belongs_to :user

  has_many :appointments , dependent: :destroy
  has_many :medical_histories , dependent: :destroy
  has_many :doctors, through: :medical_histories , dependent: :destroy

  enum blood_type: { "A+"=> 0, "A-"=> 1, "B+"=> 2,  "B-"=> 3, "AB+"=> 4, "AB-"=> 5, "O+"=> 6, "O-"=> 7}
  enum marital_status: {"single"=> 0, "married"=> 1, "divorced"=> 2, "widowed"=>3}
  validates :blood_type, presence: true
  validates :emergency_contact, presence: true
end
