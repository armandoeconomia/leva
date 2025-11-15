class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :medical_institutes
  has_one :doctor
  has_one :patient

  enum gender: { masculino: 0, femenino: 1, otro: 2 }
  validates :gender, presence: true

  validates :name, presence: true
  #Tener en cuenta que si nos falla, debemos eliminar de la 16 a la 20, se sobreescribe el codigo
  validates :last_name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, on: :create, length: { minimum: 8 }
  validates :identification, uniqueness: true

end
