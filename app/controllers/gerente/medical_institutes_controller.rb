class Gerente::MedicalInstitutesController < Gerente::BaseController
  before_action :set_medical_institute, only: %i[show edit update destroy]

  def index
    @medical_institutes = MedicalInstitute.includes(:user, :doctors).order(:name)
  end

  def show
    @doctors = @medical_institute.doctors.includes(:user)
    @appointment_count = Appointment.joins(:doctor)
                                    .where(doctors: { medical_institute_id: @medical_institute.id })
                                    .count
    @revenue = @appointment_count * Gerente::DashboardController::DEFAULT_APPOINTMENT_COST
  end

  def new
    @medical_institute = MedicalInstitute.new
    @users = User.where.not(id: User.joins(:medical_institutes).select(:id)).order(:name, :last_name)
  end

  def edit
    @users = User.order(:name, :last_name)
  end

  def create
    @medical_institute = MedicalInstitute.new(medical_institute_params)
    if @medical_institute.save
      redirect_to gerente_medical_institute_path(@medical_institute), notice: "Ubicación creada correctamente."
    else
      @users = User.order(:name, :last_name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @medical_institute.update(medical_institute_params)
      redirect_to gerente_medical_institute_path(@medical_institute), notice: "Ubicación actualizada."
    else
      @users = User.order(:name, :last_name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @medical_institute.destroy
    redirect_to gerente_medical_institutes_path, notice: "Ubicación cerrada y eliminada.", status: :see_other
  end

  private

  def set_medical_institute
    @medical_institute = MedicalInstitute.find(params[:id])
  end

  def medical_institute_params
    params.require(:medical_institute).permit(
      :user_id, :name, :address, :phone_number,
      :emergency_phone_number, :institute_type,
      :latitude, :longitude
    )
  end
end
