class Admin::DoctorsController < Admin::BaseController
  before_action :set_doctor, only: %i[show edit update destroy]

  def index
    @doctors = Doctor.includes(:user, :medical_institute)
  end

  def show; end

  def new
    @doctor = Doctor.new
  end

  def edit; end

  def create
    @doctor = Doctor.new(doctor_params)
    if @doctor.save
      redirect_to admin_doctor_path(@doctor), notice: "Doctor created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @doctor.update(doctor_params)
      redirect_to admin_doctor_path(@doctor), notice: "Doctor updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @doctor.destroy
    redirect_to admin_doctors_path, notice: "Doctor deleted"
  end

  private

  def set_doctor
    @doctor = Doctor.find(params[:id])
  end

  def doctor_params
    params.require(:doctor).permit(
      :user_id, :medical_institute_id, :speciality,
      :medical_registration
    )
  end
end
