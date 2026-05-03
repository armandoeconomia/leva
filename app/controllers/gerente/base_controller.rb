class Gerente::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_gerente!

  layout "panel"

  private

  def verify_gerente!
    redirect_to root_path, alert: "No autorizado" unless current_user.gerente?
  end
end
