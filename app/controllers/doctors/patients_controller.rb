class Doctors::PatientsController < Doctors::BaseController
  def index
    @doctor = current_user.doctor
    @patients = Patient.joins(:appointments)
                       .includes(:user)
                       .where(appointments: { doctor_id: @doctor.id })
                       .distinct
                       .order("users.name")
  end

  def show
    @doctor = current_user.doctor
    @patient = Patient.joins(:appointments)
                      .where(appointments: { doctor_id: @doctor.id })
                      .find(params[:id])
    @medical_histories = @patient.medical_histories.where(doctor: @doctor).order(registration_date: :desc)
    @appointments = @patient.appointments.where(doctor: @doctor).order(date: :desc)
  end
end
