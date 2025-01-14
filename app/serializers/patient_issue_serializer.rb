class PatientIssueSerializer < ActiveModel::Serializer

  attributes :full_name,
             :adherence,
             :last_contacted,
             :priority,
             :channel_id,
             :last_general_resolution,
             :id,
             :weeks_in_treatment,
             :unresolved_reports,
             :treatment_start,
             :photo_days_since_last_resolution,
             :photo_schedule,
             :next_reminder,
             :most_recent_report,
             :most_recent_photo_report

  has_many :unreviewed_photos do
    object.photo_reports.needs_approval
  end

  def unresolved_reports
    if (!@instance_options[:reports].nil? && !@instance_options[:reports][object.id].nil?)
      return ActiveModelSerializers::SerializableResource.new(@instance_options[:reports][object.id])
    end
    return []
  end

  def channel_id
    object.channels.where(is_private: true).first.id
  end

  def next_reminder
    object.next_reminder
  end


end
