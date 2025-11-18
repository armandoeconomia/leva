class Patients::DashboardController < Patients::BaseController
  def show
    @upcoming_appointments = @patient.appointments.order(date: :asc, hour: :asc)
    @recent_medical_histories = @patient.medical_histories.order(registration_date: :desc).limit(5)
  end
end
