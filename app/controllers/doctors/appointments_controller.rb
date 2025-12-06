class Doctors::AppointmentsController < ApplicationController
  before_action :require_doctor!
  before_action :set_appointment, only: [:show, :edit, :update, :destroy, :confirm, :cancel, :notes, :save_notes]

  def index
    @appointments = current_user.doctor.appointments.order(date: :asc)
  end

  def show
  end

  def notes
    @history = MedicalHistory.new
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
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream_payload
      end
      format.html { redirect_back fallback_location: doctors_appointments_path, notice: 'Cita confirmada.' }
    end
  end

  def cancel
    @appointment.update(status: :cancelado)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream_payload
      end
      format.html { redirect_back fallback_location: doctors_appointments_path, alert: 'Cita cancelada.' }
    end
  end

  def save_notes
    @history = MedicalHistory.new(history_params.merge(
      patient: @appointment.patient,
      doctor: current_user.doctor,
      registration_date: Date.today
    ))

    if @history.save
      redirect_to doctors_appointment_path(@appointment), notice: "Notas guardadas correctamente."
    else
      flash.now[:alert] = "No se pudieron guardar las notas."
      render :notes, status: :unprocessable_entity
    end
  end

  private

  def turbo_stream_payload
    [
      turbo_stream.replace(
        view_context.dom_id(@appointment, :dashboard_row),
        partial: "doctors/dashboard/appointment_row",
        locals: { appointment: @appointment }
      ),
      turbo_stream.replace(
        view_context.dom_id(@appointment, :index_row),
        partial: "doctors/appointments/appointment_row",
        locals: { appointment: @appointment }
      )
    ]
  end

  def set_appointment
    @appointment = current_user.doctor.appointments.find(params[:id])
  end

  def history_params
    params.require(:medical_history).permit(:diagnosis, :treatment, :prescription)
  end

  def require_doctor!
    redirect_to root_path, alert: "No tienes acceso como doctor" unless current_user&.doctor.present?
  end

  def appointment_params
    params.require(:appointment).permit(:date, :hour, :reason_for_consultation, :status)
  end
end
