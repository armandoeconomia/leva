class Admin::DashboardController < Admin::BaseController
  def show
    @total_users = User.count
    @total_patients = Patient.count
    @total_doctors = Doctor.count
    @appointments_today = Appointment.where(date: Date.today).count
  end
end
