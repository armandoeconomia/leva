class Calendar < ApplicationRecord
  belongs_to :doctor
  has_many  :hours
end
