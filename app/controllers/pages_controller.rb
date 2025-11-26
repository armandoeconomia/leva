class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    if user_signed_in?
      return redirect_to patients_dashboard_path(current_user) if current_user.patient
      return redirect_to doctors_dashboard_path(current_user) if current_user.doctor
      return redirect_to admin_dashboard_path(current_user) if current_user.admin
    end

    @medical_institutes = MedicalInstitute.where.not(latitude: nil, longitude: nil)
    @featured_doctors = Doctor.includes(:user, :medical_institute).order(created_at: :desc).limit(9)
  end
end
