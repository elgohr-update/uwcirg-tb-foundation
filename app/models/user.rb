require "webpush"

class User < ApplicationRecord
  belongs_to :organization
  has_many :messages,dependent: :destroy
  has_many :channels,dependent: :destroy
  has_many :messaging_notifications, dependent: :destroy

  enum locale: { "en": 0, "es-AR": 1 }
  enum type: { Patient: 0, Practitioner: 1, Administrator: 2 }
  enum status: { Pending: 0, Active: 1, Archived: 2 }
  enum gender: { Male: 0, Female: 1, Other: 2 }

  validates :password_digest, presence: true
  validates :email, uniqueness: true, allow_nil: true
  validates :phone_number, uniqueness: true, allow_nil: true

  after_create :create_unread_messages

  def full_name
    "#{self.given_name} #{self.family_name}"
  end

  def as_fhir_json(*args)
    return {
             givenName: given_name,
             familyName: family_name,
             identifier: [
               { value: id, use: "official" },
               { value: "test", use: "messageboard" },
             ],
             managingOrganization: managing_organization,

           }
  end

  def user_specific_channels
    if (self.type == "Patient")
      return Channel.where(is_private: false).or(Channel.where(is_private: true, user_id: self.id)).sort_by &:created_at
    end

    if (self.type == "Practitioner")
      return Channel.joins(:user).where(is_private: true, users: { organization_id: self.organization_id }).or(Channel.joins(:user).where(is_private: false)).sort_by &:created_at
    end

    return []
  end

  def send_push_to_user(title, body, app_url = "/", type = nil)

    #Check to make sure their subscription information is up to date
    if (self.push_url.nil? || self.push_auth.nil? || self.push_p256dh.nil?)
      return
    end

    data = { url: app_url }

    if (!type.nil?)
      data[:type] = type
    end

    message = JSON.generate(
      title: "#{title}",
      body: "#{body}",
      url: "#{ENV["URL_CLIENT"]}",
      data: data,
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

  def update_last_message_seen(channel_id, number)
    MessagingNotification.where(channel_id: channel_id, user_id: self.id).first.update(read_message_count: number)
  end

  def create_unread_messages
    Channel.all.map do |c|
      #TODO make sure coordinator would also get unread message here
      if (!c.is_private || (c.is_private && self.id == c.user_id))
        self.messaging_notifications.create!(channel_id: c.id, user_id: self.id, read_message_count: 0)
      end
    end
  end

  def send_message_no_push(body, channel_id)
    one = self.messages.new(body: body, channel_id: channel_id)
    one.skip_notify = true
    one.save
  end
end
