class Admin::AppointmentsController < Admin::BaseController
  before_action :set_appointment, only: %i[show edit update destroy]

  def index
    @filter_params = filter_params
    @appointments = Appointment.includes(patient: :user, doctor: :user)
    @appointments = apply_filters(@appointments, @filter_params)
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

  def filter_params
    params.permit(:patient_query, :doctor_query, :date_from, :date_to, :hour)
  end

  def apply_filters(scope, filters)
    filtered = scope

    if filters[:patient_query].present?
      filtered = filtered.where(patient_id: patients_matching(filters[:patient_query]))
    end

    if filters[:doctor_query].present?
      filtered = filtered.where(doctor_id: doctors_matching(filters[:doctor_query]))
    end

    if filters[:date_from].present?
      date = parse_date(filters[:date_from])
      filtered = filtered.where("appointments.date >= ?", date) if date
    end

    if filters[:date_to].present?
      date = parse_date(filters[:date_to])
      filtered = filtered.where("appointments.date <= ?", date) if date
    end

    if filters[:hour].present?
      filtered = filtered.where("to_char(appointments.hour, 'HH24:MI') = ?", filters[:hour])
    end

    filtered.order(date: :desc, hour: :asc)
  end

  def patients_matching(term)
    like_term = like_pattern(term)
    Patient.joins(:user).where(
      "users.name ILIKE :term OR users.last_name ILIKE :term OR "\
      "CONCAT(users.name, ' ', users.last_name) ILIKE :term OR users.email ILIKE :term",
      term: like_term
    ).select(:id)
  end

  def doctors_matching(term)
    like_term = like_pattern(term)
    Doctor.joins(:user).where(
      "users.name ILIKE :term OR users.last_name ILIKE :term OR "\
      "CONCAT(users.name, ' ', users.last_name) ILIKE :term OR users.email ILIKE :term",
      term: like_term
    ).select(:id)
  end

  def parse_date(value)
    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def like_pattern(value)
    sanitized = ActiveRecord::Base.sanitize_sql_like(value.to_s.squish)
    "%#{sanitized}%"
  end
end
