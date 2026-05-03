class Admin::DashboardController < Admin::BaseController
  def show
    @total_patients = Patient.count
    @total_doctors = Doctor.count
    @appointments_today = Appointment.where(date: Date.today).count
    @appointments_pending = Appointment.where(status: :pendiente).count

    @todays_appointments = Appointment
                             .includes(patient: :user, doctor: :user)
                             .where(date: Date.today)
                             .order(:hour)

    @upcoming_appointments = Appointment
                               .includes(patient: :user, doctor: :user)
                               .where("date > ?", Date.today)
                               .order(:date, :hour)
                               .limit(8)

    @recent_patients = Patient.includes(:user).order("patients.created_at DESC").limit(5)
    @doctors = Doctor.includes(:user, :medical_institute).order("users.name").joins(:user)
  end
end
