class Doctors::CalendarsController < ApplicationController
  before_action :require_doctor!
  before_action :set_doctor
  before_action :set_calendar, only: [:show, :edit, :update, :destroy]

  def index
    @calendars = @doctor.calendars.includes(:hours).order(date: :asc)
  end

  def show
    @appointments = Appointment.where(date: @calendar.date, doctor: @doctor)
  end

  def new
    @calendar = @doctor.calendars.new
  end

  def create
    @calendar = @doctor.calendars.new(calendar_params)
    if @calendar.save
      redirect_to doctors_calendar_path(@calendar), notice: "Calendario creado con éxito."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @calendar.update(calendar_params)
      redirect_to doctors_calendar_path(@calendar), notice: "Calendario actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @calendar.hours.destroy_all
    redirect_to doctors_hours_path, notice: "Día bloqueado; sin horarios disponibles."
  end

  private

  def set_calendar
    @calendar = @doctor.calendars.find(params[:id])
  end

  def calendar_params
    params.require(:calendar).permit(:date)
  end

  def require_doctor!
    redirect_to root_path, alert: "No estás autorizado para ver esta sección." unless current_user&.doctor.present?
  end

  def set_doctor
    @doctor = current_user.doctor
  end
end
