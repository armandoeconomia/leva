class MedicalInstitute < ApplicationRecord
  belongs_to :user

  has_many :doctors
end
