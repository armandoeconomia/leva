class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  def after_sign_in_path_for(resource)
    return doctors_dashboard_path(resource) if resource.doctor.present?
    return patients_dashboard_path(resource) if resource.patient.present?
    return admin_dashboard_path(resource) if resource.admin.present?
    super
  end
end
