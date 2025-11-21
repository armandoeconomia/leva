class AppointmentMailer < ApplicationMailer
  def status_changed
    @appointment = params[:appointment]
    @actor = params[:actor]
    @patient = @appointment.patient
    @doctor = @appointment.doctor

    recipients = [@patient.user.email, @doctor.user.email].compact.uniq
    mail(
      to: recipients,
      subject: "Actualización de cita con #{@doctor.user.name}"
    )
  end
end
