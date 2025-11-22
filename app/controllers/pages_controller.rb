class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    redirect_to patients_dashboard_path(current_user) if user_signed_in? && current_user.patient
    redirect_to doctors_dashboard_path(current_user) if user_signed_in? && current_user.doctor
    redirect_to admin_dashboard_path(current_user) if user_signed_in? && current_user.admin
  end
end
