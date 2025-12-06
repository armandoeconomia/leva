class Doctors::HoursController < ApplicationController
  before_action :require_doctor!
  before_action :set_doctor
  before_action :set_hour, only: [:destroy]
  before_action :set_calendar, only: [:new, :create]

  def index
    per_page = 10
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    @total_calendars = @doctor.calendars.count
    @calendars = @doctor.calendars.includes(:hours).order(date: :asc).offset((page - 1) * per_page).limit(per_page)
    @next_page = (page * per_page) < @total_calendars ? page + 1 : nil
    @prev_page = page > 1 ? page - 1 : nil
  end

  def new
  end

  def create
    @hour = @calendar.hours.new(hour_params)
    if @hour.save
      redirect_to new_doctors_calendar_hour_path(@calendar), notice: "Hora guardada."
    else
      @hours = @calendar.hours.order(:start_time)
      flash.now[:alert] = "No se pudo guardar la hora."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
  end

  def destroy
    calendar = @hour.calendar
    @hour.destroy
    redirect_to doctors_hours_path, notice: "Horario eliminado para #{calendar.date&.strftime('%d %b %Y')}"
  end

  private

  def set_doctor
    @doctor = current_user.doctor
  end

  def set_calendar
    @calendar = if params[:calendar_id]
                  @doctor.calendars.find_by(id: params[:calendar_id])
                else
                  @doctor.calendars.order(date: :asc).first
                end
    @hours = @calendar ? @calendar.hours.order(:start_time) : []
  end

  def set_hour
    @hour = @doctor.hours.find(params[:id])
  end

  def hour_params
    params.require(:hour).permit(:start_time, :end_time)
  end

  def require_doctor!
    redirect_to root_path, alert: "No tienes acceso como doctor" unless current_user&.doctor.present?
  end
end
