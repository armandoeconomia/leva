class Doctors::DoctorController < ApplicationController
  before_action :require_doctor!
  before_action :set_doctor

  def show
  end

  def edit
  end

  def update
    Doctor.transaction do
      @doctor.update!(doctor_params)
      @doctor.user.update!(user_params)
    end
    redirect_to doctors_doctor_path, notice: "Perfil actualizado correctamente."
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "No se pudo actualizar el perfil. Revisa los campos."
    render :edit, status: :unprocessable_entity
  end

  private

  def set_doctor
    @doctor = current_user.doctor
  end

  def require_doctor!
    redirect_to root_path, alert: "No tienes acceso como doctor" unless current_user&.doctor.present?
  end

  def doctor_params
    params.require(:doctor).permit(:medical_registration, :speciality, :medical_institute_id)
  end

  def user_params
    params.require(:doctor).fetch(:user_attributes, {}).permit(:name, :last_name, :phone_number, :email)
  end
end
