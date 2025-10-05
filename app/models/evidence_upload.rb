class EvidenceUpload < ApplicationRecord
  self.primary_key = 'evidenceupload_id'

  belongs_to :student, foreign_key: :student_id
  belongs_to :question_response, foreign_key: :questionresponse_id, optional: true

  validates :link, presence: true
  validate :drive_link_format

  # Accepts common Google Drive URL forms and file/folder links
  DRIVE_URL_REGEX = %r{\Ahttps?://(?:drive\.google\.com|docs\.google\.com)/(?:file/d/|open\?|drive/folders/).+}i

  def drive_link_format
    return if link.blank?
    unless link =~ DRIVE_URL_REGEX
      errors.add(:link, 'must be a Google Drive file or folder link')
    end
  end
end
