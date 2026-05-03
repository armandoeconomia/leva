class Gerente::DashboardController < Gerente::BaseController
  DEFAULT_APPOINTMENT_COST = 35_000

  def show
    @total_revenue_all_time = total_revenue_all_time
    @total_appointments_all_time = Appointment.where(status: :completado).count
    @monthly_data = monthly_sales_data
    @sales_summary = build_sales_summary(@monthly_data)
    @institutes = MedicalInstitute.includes(:user).order(:name)
    @revenue_by_institute = revenue_by_institute
    @appointments_by_status = appointments_by_status
  end

  private

  def monthly_sales_data
    window_start = 6.months.ago.beginning_of_month
    window_end = Date.today.end_of_month
    scope = Appointment.where(date: window_start..window_end, status: :completado).where.not(date: nil)

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

  def build_sales_summary(points)
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

  def total_revenue_all_time
    count = Appointment.where(status: :completado).count
    if Appointment.column_names.include?("cost")
      Appointment.where(status: :completado).sum(:cost).to_f
    else
      count * DEFAULT_APPOINTMENT_COST
    end
  end

  def revenue_by_institute
    MedicalInstitute.includes(doctors: :appointments).map do |institute|
      completed = institute.doctors.flat_map { |d| d.appointments.select { |a| a.status == "completado" } }
      {
        name: institute.name,
        appointments: completed.count,
        revenue: completed.count * DEFAULT_APPOINTMENT_COST
      }
    end
  end

  def appointments_by_status
    {
      pendiente: Appointment.where(status: :pendiente).count,
      completado: Appointment.where(status: :completado).count,
      cancelado: Appointment.where(status: :cancelado).count
    }
  end
end
