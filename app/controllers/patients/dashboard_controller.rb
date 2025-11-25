class Patients::DashboardController < Patients::BaseController
  def show
    @upcoming_appointments = @patient.appointments.order(date: :asc, hour: :asc)
    @recent_medical_histories = @patient.medical_histories.order(registration_date: :desc).limit(5)
    patient_conversation = current_user.ai_conversations.find_by(role: :patient)
    @recent_exam_uploads = if patient_conversation
                             patient_conversation.ai_messages.with_stored_exam.order(created_at: :desc).limit(3)
                           else
                             []
                           end
  end
end
