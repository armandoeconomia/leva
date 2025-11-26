require "ostruct"

class Patients::DoctorsController < Patients::BaseController
  def index
    @q = params[:q].to_s.strip
    @city = params[:city].to_s.strip
    @date = params[:date].presence

    doctors = Doctor.includes(:medical_institute, :user)

    if @q.present?
      q_like = "%#{@q}%"
      speciality_values = Doctor.specialities.select { |k, _| k.downcase.include?(@q.downcase) || k.humanize.downcase.include?(@q.downcase) }.values
      conditions = ["users.name ILIKE :q OR users.last_name ILIKE :q"]
      params_hash = { q: q_like }
      if speciality_values.any?
        conditions[0] += " OR doctors.speciality IN (:specs)"
        params_hash[:specs] = speciality_values
      end
      doctors = doctors.joins(:user).where(conditions.join(" " ), params_hash)
    end

    if @city.present?
      city_like = "%#{@city}%"
      doctors = doctors.joins(:medical_institute).where("medical_institutes.address ILIKE :city OR medical_institutes.name ILIKE :city", city: city_like)
    end

    if @date.present?
      doctors = doctors.joins(:calendars).where(calendars: { date: @date })
    end

    @doctors = doctors.distinct
    @speciality_options = Doctor.specialities.keys.map { |key| key.humanize }.sort
    @location_options = MedicalInstitute.order(:name).pluck(:address).compact.uniq

    selected_date = begin
                      @date.present? ? Date.parse(@date) : Date.today
                    rescue ArgumentError
                      Date.today
                    end
    start_calendar = selected_date.beginning_of_month.beginning_of_week(:monday)
    end_calendar = selected_date.end_of_month.end_of_week(:sunday)
    @calendar_weeks = (start_calendar..end_calendar).to_a.each_slice(7).to_a
    @calendar_month_label = selected_date.strftime("%B %Y")
    @calendar_month = selected_date.month
    @calendar_selected_date = selected_date
  end

  def show
    @doctor = Doctor.includes(:medical_institute, :user).find(params[:id])
    @upcoming_calendars = @doctor
                          .calendars
                          .includes(:hours)
                          .where("date >= ?", Date.today)
                          .order(:date)
                          .limit(14)

    relevant_dates = @upcoming_calendars.map(&:date)
    @booked_slots = @doctor
                    .appointments
                    .where(date: relevant_dates)
                    .where.not(status: Appointment.statuses[:cancelado])
                    .each_with_object({}) do |appointment, hash|
                      hour_key = appointment.hour&.strftime("%H:%M")
                      next if hour_key.blank?

                      hash[[appointment.date, hour_key]] = appointment
                    end

    @calendar_cards = if @upcoming_calendars.any?
                        @upcoming_calendars
                      else
                        Array.new(5) { |i| OpenStruct.new(date: Date.today + i.days, hours: Hour.none) }
                      end
  end
end
