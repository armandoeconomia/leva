class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def after_sign_in_path_for(resource)
    return doctors_dashboard_path if resource.doctor?
    return gerente_dashboard_path if resource.gerente?
    return admin_dashboard_path if resource.admin?
    root_path
  end
end
