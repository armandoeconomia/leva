class AiConversation < ApplicationRecord
  belongs_to :user
  has_many :ai_messages, dependent: :destroy

  enum role: { patient: 0, doctor: 1, admin: 2 }

  validates :role, presence: true

  def display_title
    title.presence || default_title
  end

  private

  def default_title
    case role
    when "doctor"
      "Asistente médico para doctores"
    when "admin"
      "Asistente operativo"
    else
      "Asistente médico"
    end
  end
end
