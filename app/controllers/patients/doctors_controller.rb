class Patients::DoctorsController < Patients::BaseController
  def index
    @doctors = Doctor.includes(:medical_institute, :user).all
  end

  def show
    @doctor = Doctor.includes(:medical_institute, :user).find(params[:id])
  end
end
