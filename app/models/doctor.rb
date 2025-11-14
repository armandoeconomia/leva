class Doctor < ApplicationRecord
  belongs_to :user
  belongs_to :medical_institute
end
