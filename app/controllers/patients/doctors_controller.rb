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
  end

  def show
    @doctor = Doctor.includes(:medical_institute, :user).find(params[:id])
  end
end
