class Doctors::DashboardsController < ApplicationController
  before_action :require_doctor!

  def show
    @doctor = current_user.doctor
    @upcoming_appointments = @doctor.appointments
                                    .includes(patient: :user)
                                    .where("date >= ?", Date.today)
                                    .order(:date, :hour)
                                    .limit(5)
    @active_patients = Patient
                         .joins(:appointments)
                         .includes(:user)
                         .where(appointments: { doctor_id: @doctor.id })
                         .distinct
                         .limit(5)
    @latest_medical_histories = @doctor.medical_histories
                                       .includes(patient: :user)
                                       .order(registration_date: :desc)
                                       .limit(4)
    week_start = Date.today.beginning_of_week(:monday)
    week_end = week_start + 6.days
    @work_hours = Hour
                    .includes(:calendar)
                    .references(:calendars)
                    .where(calendars: { doctor_id: @doctor.id, date: week_start..week_end })
                    .order("calendars.date ASC", :start_time)
    @medical_institute = @doctor.medical_institute
  end

  private

  def require_doctor!
    redirect_to root_path, alert: "No tienes acceso como doctor" unless current_user&.doctor.present?
  end
end
