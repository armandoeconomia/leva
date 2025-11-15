class MedicalHistory < ApplicationRecord
  belongs_to :patient
  belongs_to :doctor

  validates :diagnosis, presence: true
end
