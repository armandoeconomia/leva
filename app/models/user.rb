class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # has_many :medical_instute, :doctor, :patient
  has_many :medical_institutes
  has_one :doctor
  has_one :patient
end
