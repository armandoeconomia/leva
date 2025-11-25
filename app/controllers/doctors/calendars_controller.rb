class Doctors::CalendarsController < ApplicationController
  before_action :set_calendar, only: [:show, :edit, :update, :destroy]

  def index
      if current_user&.doctor
        @calendars = current_user.doctor
                                  .calendars
                                  .joins(:hours)
                                  .joins("INNER JOIN appointments ON appointments.hour = hours.start_time AND appointments.date = calendars.date")
                                  .distinct
      else
        redirect_to root_path, alert: "No estás autorizado para ver esta sección."
      end
  end

  def show
  @calendar = current_user.doctor.calendars.find(params[:id])
  @appointments = Appointment.where(date: @calendar.date, doctor: current_user.doctor)
  end

  def new
    @calendar = current_user.doctor.calendars.new
  end

  def create
    @calendar = current_user.doctor.calendars.new(calendar_params)
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
    @calendar.destroy
    redirect_to doctors_calendars_path, notice: "Calendario eliminado."
  end

  private

  def set_calendar
    @calendar = current_user.doctor.calendars.find(params[:id])
  end

  def calendar_params
    params.require(:calendar).permit(:date)
  end
end
