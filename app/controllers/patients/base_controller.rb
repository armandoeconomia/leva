class Patients::BaseController < ApplicationController #Defino controlador base para pacientes lo heredara todo lo que este dentro de namespace Patients
  before_action :authenticate_user! # metodo que viene de Devise
  before_action :require_patient! # metodo para verificar que la persona que ingresa es paciente
  before_action :set_patient # abreviacion para tener que escribir current_user.patient

  private

  def set_patient
    @patient = current_user.patient #obtiene el perfil del paciente asociado al usuario actual
  end

  def require_patient!
    redirect_to root_path, alert: "No tienes acceso como paciente" unless current_user&.patient # especifica el acceso unicamente para el paciente, nadie mas puede acceder a su perfil
  end
end
