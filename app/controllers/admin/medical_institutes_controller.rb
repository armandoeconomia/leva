class Admin::MedicalInstitutesController < Admin::BaseController
  before_action :set_medical_institute, only: %i[show edit update destroy]

  def index
    @medical_institutes = MedicalInstitute.all
  end

  def show; end

  def new
    @medical_institute = MedicalInstitute.new
  end

  def edit; end

  def create
    @medical_institute = MedicalInstitute.new(medical_institute_params)
    if @medical_institute.save
      redirect_to admin_medical_institute_path(@medical_institute), notice: "Institute created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @medical_institute.update(medical_institute_params)
      redirect_to admin_medical_institute_path(@medical_institute), notice: "Institute updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @medical_institute.destroy
    redirect_to admin_medical_institutes_path, notice: "Institute deleted"
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
