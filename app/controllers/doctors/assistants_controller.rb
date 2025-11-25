class Doctors::AssistantsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_doctor!
  before_action :set_conversation

  def show
    @messages = @conversation.ai_messages.order(:created_at)
    @assistant_context = Ai::AssistantService.context_for(user: current_user, role: :doctor)
  end

  def message
    if message_params[:content].blank?
      redirect_to doctors_assistant_path, alert: "Comparte tu consulta para que el asistente pueda ayudarte."
      return
    end

    user_message = @conversation.ai_messages.create!(sender: :user, content: message_params[:content])
    Ai::AssistantService.new(conversation: @conversation).respond_to!(user_message)
    redirect_to doctors_assistant_path, notice: "Consulta enviada al asistente médico."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to doctors_assistant_path, alert: error.record.errors.full_messages.to_sentence
  end

  private

  def require_doctor!
    redirect_to root_path, alert: "No autorizado" unless current_user&.doctor
  end

  def set_conversation
    @conversation = current_user.ai_conversations.find_or_create_by!(role: :doctor)
  end

  def message_params
    params.require(:chat).permit(:content)
  end
end
