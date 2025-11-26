class AiMessage < ApplicationRecord
  belongs_to :ai_conversation

  has_many_attached :documents

  enum sender: { user: 0, assistant: 1 }

  scope :with_stored_exam, -> { where(stored_exam: true) }

  validates :content, presence: true, unless: :documents_attached?

  def content_with_attachments
    body = content.presence || "Sin texto proporcionado."
    return body if documents.blank?

    attachment_names = documents.map { |doc| doc.filename.to_s }
    "#{body}\n\nArchivos adjuntos: #{attachment_names.join(', ')}"
  end

  private

  def documents_attached?
    documents.attached?
  end
end
