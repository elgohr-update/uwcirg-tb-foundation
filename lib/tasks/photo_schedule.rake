namespace :photo_schedule do
  desc "Deletes all scheduled photos after current week. Creates new scheudle at 2 per week"
  task :fix_future_schedule => :environment do
    users = Patient.all
    puts "Going to update #{users.count} patients"

    ActiveRecord::Base.transaction do
      weekdays_array = (1..5).to_a

      users.each do |patient|

        #Delete future requests
        patient.photo_days.where("date > ?", Date.today.end_of_week).destroy_all
        date = patient.treatment_start
        i = 0

        #Check this week - could use to delete the 3rd one for this week
        count_week = patient.photo_days.where("date >= ? AND date <= ?", date.beginning_of_week(start_day = :sunday), date.end_of_week(start_day = :sunday)).count

        while i < (28)
          weekly_photo_sum = 2

          #Move to Sunday, so we can add weekday to get randomized day
          date = date.beginning_of_week(start_day = :sunday)

          #Select randomized weekdays from array
          selected_weekdays = weekdays_array.shuffle.take(weekly_photo_sum)
          end_week = date.end_of_week(start_day = :sunday)

          #Map these weekdays to DB rows
          selected_weekdays.each do |weekday|
            new_date = date + weekday.days
            if (new_date > Date.today.end_of_week(start_day = :sunday))
              patient.photo_days.create!(date: new_date)
            end
          end
          date = date + 1.week
          i += 1
        end
        puts "Patient #{patient.id} done now!"
      end
    end
  end
end
