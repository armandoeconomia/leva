class Doctors::AppointmentsController < ApplicationController
  before_action :set_appointment, only: [:show, :edit, :update, :destroy, :confirm, :cancel]

  def index
    @appointments = Appointment.where(doctor: current_user.doctor).order(date: :asc)
  end

  def show
  end

  def edit
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to doctors_appointment_path(@appointment), notice: 'Cita actualizada correctamente.'
    else
      render :edit
    end
  end

  def destroy
    @appointment.destroy
    redirect_to doctors_appointments_path, notice: 'Cita eliminada.'
  end

  def confirm
    @appointment.update(status: :completado)
    redirect_to doctors_appointments_path, notice: 'Cita confirmada.'
  end

  def cancel
    @appointment.update(status: :cancelado)
    redirect_to doctors_appointments_path, alert: 'Cita cancelada.'
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:date, :hour, :reason_for_consultation, :status)
  end
end
