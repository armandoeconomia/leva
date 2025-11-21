class Patients::AppointmentsController < Patients::BaseController
  before_action :set_doctors, only: [:new, :create, :edit, :update]
  before_action :set_appointment, only: [:show, :edit, :update, :destroy]

  def index
    @appointments = @patient.appointments.includes(:doctor).order(date: :desc, hour: :desc)
  end

  def show; end

  def new
    @appointment = @patient.appointments.new
  end

  def create
    @appointment = @patient.appointments.new(appointment_params)
    @appointment.status ||= :pendiente

    if @appointment.save
      redirect_to patients_appointment_path(@appointment), notice: "Cita creada"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @appointment.update(appointment_params)
      redirect_to patients_appointment_path(@appointment), notice: "Cita actualizada"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @appointment.destroy
    redirect_to patients_appointments_path, notice: "Cita eliminada"
  end

  private

  def set_appointment
    @appointment = @patient.appointments.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:doctor_id, :date, :hour, :reason_for_consultation)
  end

  def set_doctors
    @doctors = Doctor.includes(:user, :medical_institute).order(:id)
  end

end
