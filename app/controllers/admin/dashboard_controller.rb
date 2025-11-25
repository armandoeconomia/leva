class Admin::DashboardController < Admin::BaseController
  def show
    @total_users = User.count
    @total_patients = Patient.count
    @total_doctors = Doctor.count
    @appointments_today = Appointment.where(date: Date.today).count
    @upcoming_appointments = Appointment
                               .includes(patient: :user, doctor: :user)
                               .where("date >= ?", Date.today)
                               .order(:date, :hour)
                               .limit(6)
  end
end
