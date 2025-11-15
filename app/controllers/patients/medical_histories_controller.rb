class Patients::MedicalHistoriesController < Patients::BaseController
  def index
    @medical_histories = @patient.medical_histories.includes(:doctor).order(registration_date: :desc)
  end

  def show
    @medical_history = @patient.medical_histories.includes(:doctor).find(params[:id])
  end
end
