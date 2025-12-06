module Ai
  class AvailabilityBuilder
    def initialize(start_date: default_start, end_date: default_start + 14.days)
      @start_date = start_date
      @end_date = end_date
    end

    def speciality_snapshot
      doctors = Doctor.includes(:user, :medical_institute, calendars: :hours)
                      .where(calendars: { date: @start_date..@end_date })
                      .references(:calendars)

      return [] if doctors.blank?

      busy_slots = load_busy_slots
      option_counter = 1

      doctors_with_availability = doctors.filter_map do |doctor|
        slots = available_slots_for(doctor, busy_slots)
        next if slots.empty?

        entry = {
          opcion: option_counter,
          especialidad: doctor.speciality&.humanize || "General",
          doctor_id: doctor.id,
          doctor: [doctor.user.name, doctor.user.last_name].compact.join(" "),
          institucion: doctor.medical_institute&.name,
          ubicacion: doctor.medical_institute&.address,
          proximos_horarios: slots.first(5)
        }
        option_counter += 1
        entry
      end

      doctors_with_availability
        .group_by { |entry| entry[:especialidad] }
        .map do |speciality, doctors_for_speciality|
          {
            especialidad: speciality,
            doctores: doctors_for_speciality.first(5)
          }
        end
    end

    private

    def default_start
      Time.zone ? Time.zone.today : Date.today
    end

    def load_busy_slots
      Appointment
        .where(date: @start_date..@end_date)
        .where.not(status: Appointment.statuses[:cancelado])
        .each_with_object({}) do |appointment, hash|
          formatted_hour = appointment.hour&.strftime("%H:%M")
          next if formatted_hour.blank?

          hash[[appointment.doctor_id, appointment.date, formatted_hour]] = true
        end
    end

    def available_slots_for(doctor, busy_slots)
      relevant_calendars = doctor.calendars.select do |calendar|
        calendar.date.present? && calendar.date >= @start_date && calendar.date <= @end_date
      end

      slots = relevant_calendars.flat_map do |calendar|
        calendar.hours.sort_by(&:start_time).filter_map do |hour|
          formatted_hour = hour.start_time&.strftime("%H:%M")
          next if formatted_hour.blank?
          next if busy_slots[[doctor.id, calendar.date, formatted_hour]]

          {
            fecha: calendar.date,
            fecha_legible: calendar.date.strftime("%A %d %B"),
            hora: formatted_hour,
            hora_fin: hour.end_time&.strftime("%H:%M")
          }
        end
      end

      slots.sort_by { |slot| [slot[:fecha], slot[:hora]] }.each_with_index.map do |slot, index|
        slot.merge(indice: index + 1)
      end
    end
  end
end
