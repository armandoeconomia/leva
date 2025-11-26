
class Admin::PatientsController < Admin::BaseController
  before_action :set_patient, only: %i[show edit update destroy]

  def index
    @patients = Patient.all.includes(:user)
  end

  def show; end

  def new
    @patient = Patient.new
  end

  def edit; end

  def create
    @patient = Patient.new(patient_params)
    if @patient.save
      redirect_to admin_patient_path(@patient), notice: "Patient created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @patient.update(patient_params)
      redirect_to admin_patient_path(@patient), notice: "Patient updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @patient.destroy
    redirect_to admin_patients_path, notice: "Patient deleted", status: :see_other
  end

  private

  def set_patient
    @patient = Patient.find(params[:id])
  end

  def patient_params
    params.require(:patient).permit(
      :user_id, :blood_type, :emergency_contact, :allergies,
      :medical_history, :pathology, :medical_insurance,
      :marital_status, :payments
    )
  end
end
