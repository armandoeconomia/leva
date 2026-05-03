class Doctors::DashboardController < Doctors::BaseController
  DEFAULT_APPOINTMENT_COST = 35_000

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
    @medical_institute = @doctor.medical_institute
    @monthly_billing = monthly_billing_data(@doctor)
    @billing_summary = build_billing_summary(@monthly_billing)
    @appointments_pending = @doctor.appointments.where(status: :pendiente).count
    @appointments_completed = @doctor.appointments.where(status: :completado).count
    @appointments_today = @doctor.appointments.where(date: Date.today).count
  end

  private

  def monthly_billing_data(doctor)
    window_start = 6.months.ago.beginning_of_month
    window_end = Date.today.end_of_month
    scope = doctor.appointments
                  .where(date: window_start..window_end, status: :completado)
                  .where.not(date: nil)

    month_trunc = Arel.sql("DATE_TRUNC('month', date)")
    counts = scope.group(month_trunc).order(month_trunc).count

    revenues =
      if Appointment.column_names.include?("cost")
        scope.group(month_trunc).sum(:cost)
      else
        counts.transform_values { |count| count * DEFAULT_APPOINTMENT_COST }
      end

    counts.keys.sort.map do |month|
      date = month.to_date
      {
        key: month,
        label: I18n.l(date, format: "%b"),
        full_label: I18n.l(date, format: "%B %Y"),
        appointments: counts[month],
        revenue: revenues[month].to_f
      }
    end
  end

  def build_billing_summary(points)
    total_revenue = points.sum { |p| p[:revenue] }
    total_appointments = points.sum { |p| p[:appointments] }
    best_month = points.max_by { |p| p[:revenue] }

    {
      total_revenue: total_revenue,
      total_appointments: total_appointments,
      average_ticket: total_appointments.positive? ? (total_revenue / total_appointments) : 0,
      best_month_label: best_month&.dig(:full_label),
      best_month_revenue: best_month&.dig(:revenue) || 0
    }
  end

end
