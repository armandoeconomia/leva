class Patients::AssistantsController < Patients::BaseController
  before_action :set_conversation

  def show
    @messages = @conversation.ai_messages.order(:created_at)
    @stored_exam_messages = @conversation.ai_messages.with_stored_exam.order(created_at: :desc).limit(6)
    @assistant_context = Ai::AssistantService.context_for(user: current_user, role: :patient)
  end

  def message
    unless message_payload_present?
      redirect_to patients_assistant_path, alert: "Escribe una pregunta o adjunta un examen para continuar."
      return
    end

    user_message = @conversation.ai_messages.create!(
      sender: :user,
      content: message_params[:content],
      stored_exam: ActiveModel::Type::Boolean.new.cast(message_params[:store_in_history])
    )
    attach_documents(user_message, message_params[:documents])

    Ai::AssistantService.new(conversation: @conversation).respond_to!(user_message)
    redirect_to patients_assistant_path, notice: "Tu mensaje fue enviado al asistente médico."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to patients_assistant_path, alert: error.record.errors.full_messages.to_sentence
  end

  def upload_exam
    if upload_params[:documents].blank?
      redirect_to patients_assistant_path, alert: "Debes adjuntar al menos un archivo para guardarlo en tu historial."
      return
    end

    notes = upload_params[:notes].presence || "Examen cargado manualmente desde el panel del paciente."
    message = @conversation.ai_messages.create!(sender: :user, content: notes, stored_exam: true)
    attach_documents(message, upload_params[:documents])

    redirect_to patients_assistant_path, notice: "Examen guardado en tu historial digital."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to patients_assistant_path, alert: error.record.errors.full_messages.to_sentence
  end

  private

  def set_conversation
    @conversation = current_user.ai_conversations.find_or_create_by!(role: :patient)
  end

  def message_params
    params.require(:chat).permit(:content, :store_in_history, documents: [])
  end

  def upload_params
    params.require(:exam).permit(:notes, documents: [])
  end

  def message_payload_present?
    message_params[:content].present? || Array(message_params[:documents]).reject(&:blank?).any?
  end

  def attach_documents(message, files)
    Array(files).reject(&:blank?).each { |file| message.documents.attach(file) }
  end
end
