class Doctors::MedicalHistoriesController < ApplicationController
  before_action :require_doctor!
  before_action :set_patient
  before_action :set_history, only: [:show]

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def show
  end

  private

  def require_doctor!
    redirect_to root_path, alert: "No tienes acceso como doctor" unless current_user&.doctor.present?
  end

  def set_patient
    @patient = Patient.includes(:user).find(params[:patient_id])
  end

  def set_history
    @histories = @patient.medical_histories.includes(:doctor, patient: :user).order(registration_date: :desc)
    @history = @histories.find_by(id: params[:id]) if params[:id].present?
    @history = nil if @history && @history.patient_id != @patient.id
    @history ||= @histories.first
    if params[:show_others].present?
      @other_histories = MedicalHistory.includes(:doctor, patient: :user)
                                       .where.not(patient_id: @patient.id)
                                       .order(registration_date: :desc)
                                       .limit(10)
    else
      @other_histories = []
    end
  end
end
