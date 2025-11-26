class Admin::AssistantsController < Admin::BaseController
  before_action :set_conversation

  def show
    @messages = @conversation.ai_messages.order(:created_at)
    @assistant_context = Ai::AssistantService.context_for(user: current_user, role: :admin)
  end

  def message
    if message_params[:content].blank?
      redirect_to admin_assistant_path, alert: "Describe tu solicitud para obtener una respuesta."
      return
    end

    user_message = @conversation.ai_messages.create!(sender: :user, content: message_params[:content])
    Ai::AssistantService.new(conversation: @conversation).respond_to!(user_message)
    redirect_to admin_assistant_path, notice: "Solicitud enviada al asistente."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to admin_assistant_path, alert: error.record.errors.full_messages.to_sentence
  end

  private

  def set_conversation
    @conversation = current_user.ai_conversations.find_or_create_by!(role: :admin)
  end

  def message_params
    params.require(:chat).permit(:content)
  end
end
