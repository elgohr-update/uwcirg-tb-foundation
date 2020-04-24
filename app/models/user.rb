require "webpush"

class User < ApplicationRecord
  has_many :messages
  has_many :channels
  has_many :unread_messages

  has_many :daily_reports
  has_many :photo_reports
  has_many :medication_reports
  has_many :symptom_reports

  has_one :daily_notification

  enum language: { en: 0, es: 1 }
  enum type: { Patient: 0, Practitioner: 1, Administrator: 2 }

  validates :password_digest, presence: true
  validates :email, uniqueness: true, allow_nil: true
  validates :phone_number, uniqueness: true, allow_nil: true

  after_create :create_unread_messages

  def as_fhir_json(*args)
    if (!self.daily_notification.nil?)
      reminderTime = self.daily_notification.formatted_time
    else
      reminderTime = ""
    end
    return {
             givenName: given_name,
             familyName: family_name,
             identifier: [
               { value: id, use: "official" },
               { value: "test", use: "messageboard" },
             ],
             treatmentStart: treatment_start,
             medicationSchedule: medication_schedule,
             managingOrganization: managing_organization,
             reminderTime: reminderTime,

           }
  end

  def seed_test_reports
    (treatment_start.to_date..DateTime.current.to_date).each do |day|
      #daily_reports.create(date: day)
      post_daily_report(day)
    end
  end

  def post_daily_report(day)
    datetime = DateTime.new(day.year, day.month, day.day, 4, 5, 6, "-04:00")

    med_report = MedicationReport.create!(user_id: self.id, medication_was_taken: [true, true, true, false].sample, datetime_taken: datetime)
    symptom_report = SymptomReport.create!(
      user_id: self.id,
      nausea: [true, false].sample,
      nausea_rating: [true, false].sample,
      redness: [true, false].sample,
      hives: [true, false].sample,
      fever: [true, false].sample,
      appetite_loss: [true, false].sample,
      blurred_vision: [true, false].sample,
      sore_belly: [true, false].sample,
      other: "Other text would go here!",
    )

    new_report = DailyReport.create(date: day, user_id: self.id)

    new_report.medication_report = med_report
    new_report.symptom_report = symptom_report
    new_report.save
  end

  def user_specific_channels
    #Modify this to attach a users notifications / push settings for each channel
    channelList = Channel.where(is_private: false).or(Channel.where(is_private: true, user_id: self.id)).sort_by &:created_at
  end

  def send_push_to_user(title, body)

    #Check to make sure their subscription information is up to date
    if (self.push_url.nil? || self.push_auth.nil? || self.push_p256dh.nil?)
      #render(json: { error: 'User has no push data' }, status: :unauthorized)
      #Dont send a notification
      return
    end

    message = JSON.generate(
      title: "#{title}",
      body: "#{body}",
      url: ENV["URL_CLIENT"],
    )

    Webpush.payload_send(
      message: message,
      endpoint: self.push_url,
      p256dh: self.push_p256dh,
      auth: self.push_auth,
      ttl: 24 * 60 * 60,
      vapid: {
        subject: "mailto:sender@example.com",
        public_key: ENV["VAPID_PUBLIC_KEY"],
        private_key: ENV["VAPID_PRIVATE_KEY"],
      },
    )
  end

  def create_unread_messages
    Channel.all.map do |c|
      #TODO make sure coordinator would also get unread message here
      if (!c.is_private || self.id == c.user_id)
        self.unread_messages.create!(channel_id: c.id, user_id: self.id, push_subscription: true,number_unread: 0)
      end
    end
  end

end
