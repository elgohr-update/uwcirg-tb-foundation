class PhotoReview < ApplicationRecord
    belongs_to :photo_report
    belongs_to :bio_engineer
    belongs_to :photo_color, optional: true
    belongs_to :test_strip_version, optional: true
  
    has_many :code_applications, dependent: :destroy
    has_many :photo_codes , :through => :code_applications

    accepts_nested_attributes_for :code_applications, allow_destroy: true
  
    enum test_line_review: {
      pending: 0,
      positive: 1,
      negative: 2,
      unclear: 3
    }, _prefix: true
  
    enum control_line_review: {
      pending: 0,
      positive: 1,
      negative: 2,
      unclear: 3
    }, _prefix: true
  
  end
  