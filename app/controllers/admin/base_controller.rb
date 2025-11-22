class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin!

  layout "admin"

  private

  def verify_admin!
    redirect_to root_path, alert: "No autorizado" unless current_user.admin?
  end
end
