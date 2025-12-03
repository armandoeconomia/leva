class Public::AssistantsController < ApplicationController
  skip_before_action :authenticate_user!

  def message
    content = chat_params[:content].to_s.strip
    if content.blank?
      render json: { error: "Escribe tu consulta para continuar." }, status: :unprocessable_entity
      return
    end

    history = chat_params[:history]&.map { |entry| entry.to_h.symbolize_keys } || []
    assistant = Ai::PublicAppointmentAssistant.new
    reply = assistant.respond_to(content, history: history)
    render json: { reply:, availability: assistant.availability_snapshot }
  rescue RubyLLM::Error => e
    Rails.logger.error("[PublicAssistant] #{e.class}: #{e.message}")
    render json: { error: "No pude consultar la disponibilidad. Intenta nuevamente." }, status: :bad_gateway
  rescue StandardError => e
    Rails.logger.error("[PublicAssistant] #{e.class}: #{e.message}")
    render json: { error: "Tuvimos un inconveniente. Intenta otra vez en unos segundos." }, status: :internal_server_error
  end

  private

  def chat_params
    params.require(:chat).permit(:content, history: %i[role content])
  end
end
