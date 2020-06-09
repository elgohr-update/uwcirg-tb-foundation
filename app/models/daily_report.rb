class DailyReport < ApplicationRecord
  belongs_to :patient, :foreign_key=> :user_id
  has_many :resolutions, through: :patient
  has_one :medication_report
  has_one :symptom_report
  has_one :photo_report

  validates :medication_report, presence: true
  validates :symptom_report, presence: true
  validates :date, presence: true

  scope :today, -> { where(:date => (Time.now.to_date)) }
  scope :last_week, ->{where("date > ?", Time.now - 1.week) }
  scope :was_taken, ->{joins(:medication_report).where(medication_reports:{medication_was_taken: true}) }
  #scope :since_last_med_resolution, -> {where("date > ?", patient.resolution.where(kind: "MissedMedication"))}
  #scope :test, -> {includes(:patient).where("date > ?", object.patient.treatment_start)}
  #scope :unresolved_symptoms, -> {joins(:resolutions).where(:symptom_report => SymptomReport.has_symptom, resolutions:{kind:"Symptom" }).where("daily_reports.date > resolutions.resolved_at" ).group("users.id","daily_reports.id","resolutions.resolved_at").having('Max(resolutions.resolved_at) >= resolutions.resolved_at')}

  scope :unresolved_symptoms, -> {joins(:resolutions).where(:symptom_report => SymptomReport.has_symptom, "resolutions.id": Resolution.last_symptom_from_user).where("daily_reports.created_at > resolutions.resolved_at")}
  scope :since_last_missing_resolution, -> {joins(:resolutions).where("resolutions.id": Resolution.last_medication_from_user).where("daily_reports.created_at > resolutions.resolved_at")}


  def limit_one
    if self.daily_reports.today.count == 1
      errors.add(:base, "Exceeds daily limit")
    end
  end

  def get_photo
    if (!self.photo_report.nil?)
      return self.photo_report.get_url
    end
    return nil
  end

  def get_photo_ref
    if(!self.photo_report.nil?)
      return self.photo_report.photo_url
    else
      return nil
    end
  end

  def symptom_summary
    return symptom_report.as_json
  end

  # def as_json(*args)
  #   report = {
  #     date: date,
  #     takenAt: medication_report.datetime_taken,
  #     createdAt: created_at,
  #     updatedAt: updated_at,
  #     medicationTaken: medication_report.medication_was_taken,
  #     whyMedicationNotTaken: medication_report.why_medication_not_taken,
  #     symptoms: symptom_report.reported_symptoms,
  #   }
  #   if (!self.photo_report.nil?)
  #     report[:photoURL] = photo_report.get_url
  #   end
  #   return report
  # end
end
