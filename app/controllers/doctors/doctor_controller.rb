class Doctors::ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @doctor = current_user.doctor
  end

  def edit
    @doctor = current_user.doctor
  end

  def update
    @doctor = current_user.doctor
    if @doctor.update(doctor_params)
      redirect_to doctors_doctor_path, notice: "Perfil actualizado con éxito"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def doctor_params
    params.require(:doctor).permit(:speciality, :medical_registration)
  end
end
