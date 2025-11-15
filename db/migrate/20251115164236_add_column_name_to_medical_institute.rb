class AddColumnNameToMedicalInstitute < ActiveRecord::Migration[7.1]
  def change
    add_column :medical_institutes, :name, :string
  end
end
