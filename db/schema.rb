# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_15_164236) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "doctor_id", null: false
    t.date "date"
    t.time "hour"
    t.text "reason_for_consultation"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id"], name: "index_appointments_on_doctor_id"
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
  end

  create_table "calendars", force: :cascade do |t|
    t.bigint "doctor_id", null: false
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id"], name: "index_calendars_on_doctor_id"
  end

  create_table "doctors", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "medical_institute_id", null: false
    t.integer "speciality"
    t.string "medical_registration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medical_institute_id"], name: "index_doctors_on_medical_institute_id"
    t.index ["user_id"], name: "index_doctors_on_user_id"
  end

  create_table "hours", force: :cascade do |t|
    t.bigint "calendar_id", null: false
    t.time "start_time"
    t.time "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_id"], name: "index_hours_on_calendar_id"
  end

  create_table "medical_histories", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "doctor_id", null: false
    t.date "registration_date"
    t.text "diagnosis"
    t.text "treatment"
    t.text "prescription"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id"], name: "index_medical_histories_on_doctor_id"
    t.index ["patient_id"], name: "index_medical_histories_on_patient_id"
  end

  create_table "medical_institutes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "address"
    t.string "phone_number"
    t.string "emergency_phone_number"
    t.integer "institute_type"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["user_id"], name: "index_medical_institutes_on_user_id"
  end

  create_table "patients", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "blood_type"
    t.string "emergency_contact"
    t.string "allergies"
    t.text "medical_history"
    t.text "pathology"
    t.string "medical_insurance"
    t.integer "marital_status" default: 0
    t.float "payments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_patients_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "last_name"
    t.string "phone_number"
    t.boolean "admin"
    t.date "birthday"
    t.string "address"
    t.string "identification"
    t.integer "gender"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "appointments", "doctors"
  add_foreign_key "appointments", "patients"
  add_foreign_key "calendars", "doctors"
  add_foreign_key "doctors", "medical_institutes"
  add_foreign_key "doctors", "users"
  add_foreign_key "hours", "calendars"
  add_foreign_key "medical_histories", "doctors"
  add_foreign_key "medical_histories", "patients"
  add_foreign_key "medical_institutes", "users"
  add_foreign_key "patients", "users"
end
