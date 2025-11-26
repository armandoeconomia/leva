class Admin::AppointmentsController < Admin::BaseController
  before_action :set_appointment, only: %i[show edit update destroy]

  def index
    @appointments = Appointment.includes(:doctor, :patient)
  end

  def show; end

  def new
    @appointment = Appointment.new
  end

  def edit; end

  def create
    @appointment = Appointment.new(appointment_params)
    if @appointment.save
      redirect_to admin_appointment_path(@appointment), notice: "Appointment created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to admin_appointment_path(@appointment), notice: "Appointment updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @appointment.destroy
    redirect_to admin_appointments_path, notice: "Appointment deleted",status: :see_other
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(
      :patient_id, :doctor_id, :date, :hour,
      :reason_for_consultation, :status
    )
  end
end
