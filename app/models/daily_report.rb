class DailyReport < ApplicationRecord
  belongs_to :user
  has_one :medication_report
  has_one :symptom_report
  has_one :photo_report

  validates :medication_report, presence: true
  validates :symptom_report, presence: true
  validates :date, presence: true

  scope :today, -> { where(:date => (Time.now.to_date)) }

  def limit_one
    if self.daily_reports.today.count == 1
      errors.add(:base, "Exceeds daily limit")
    end
  end

  def get_photo_ref
    if(!self.photo_report.nil?)
      return self.photo_report.photo_url
    else
      return nil
    end
  end

  def test_json(*args)
    hash = {}
    hash["#{date}"] = as_json
    return hash
  end

  def as_json(*args)
    report = {
      date: date,
      takenAt: medication_report.datetime_taken,
      createdAt: created_at,
      updatedAt: updated_at,
      medicationTaken: medication_report.medication_was_taken,
      whyMedicationNotTaken: medication_report.why_medication_not_taken,
      symptoms: symptom_report.reported_symptoms,
    }
    if (!self.photo_report.nil?)
      report[:photoURL] = photo_report.photo_url
    end
    return report
  end
end