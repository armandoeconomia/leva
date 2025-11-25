class Doctors::DashboardController < ApplicationController
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
    @work_hours = Hour
                    .includes(:calendar)
                    .references(:calendars)
                    .where(calendars: { doctor_id: @doctor.id })
                    .order("calendars.date ASC", :start_time)
                    .limit(7)
    @medical_institute = @doctor.medical_institute
  end

  private

  def require_doctor!
    redirect_to root_path, alert: "No tienes acceso como doctor" unless current_user&.doctor.present?
  end
end
