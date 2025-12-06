class Admin::DashboardController < Admin::BaseController
  DEFAULT_APPOINTMENT_COST = 35_000

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
    @sales_chart_data = monthly_sales_data
    @sales_summary = build_sales_summary(@sales_chart_data)
  end

  private

  def monthly_sales_data
    window_start = 5.months.ago.beginning_of_month
    window_end = Date.today.end_of_month
    scope = Appointment.where(date: window_start..window_end).where.not(date: nil)

    month_trunc = Arel.sql("DATE_TRUNC('month', date)")
    counts = scope.group(month_trunc).order(month_trunc).count
    return [] if counts.empty?

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

  def build_sales_summary(points)
    total_revenue = points.sum { |point| point[:revenue] }
    total_appointments = points.sum { |point| point[:appointments] }
    best_month = points.max_by { |point| point[:revenue] }

    {
      total_revenue: total_revenue,
      total_appointments: total_appointments,
      average_ticket: total_appointments.positive? ? (total_revenue / total_appointments) : 0,
      best_month_label: best_month&.dig(:full_label),
      best_month_revenue: best_month&.dig(:revenue) || 0
    }
  end
end
