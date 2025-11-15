class MedicalInstitute < ApplicationRecord
  belongs_to :user

  has_many :doctors

  validates :name, presence: true
  validates :address, presence: true
  validates :phone_number, presence: true
  validates :user_id, presence: true
  # Esto lo deberia validar la Gema de Geocoder
  # validates :latitude, numericality: { allow_blank: true, greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  # validates :longitude, numericality: { allow_blank: true, greater_than_or_equal_to: -180, less_than_or_equal_to: 180}
  enum institute_type: { publico: 0, privado: 1 }
  validates :institute_type, presence: true
end
