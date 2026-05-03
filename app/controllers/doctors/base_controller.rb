class Doctors::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_doctor!

  layout "panel"

  private

  def require_doctor!
    redirect_to root_path, alert: "No tienes acceso como doctor" unless current_user&.doctor.present?
  end
end
