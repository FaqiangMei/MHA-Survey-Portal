class SurveyAssignment < ApplicationRecord
  belongs_to :survey
  belongs_to :advisor, class_name: "Advisor", foreign_key: :advisor_id, primary_key: :advisor_id

  validates :advisor_id, presence: true
  validates :survey_id, uniqueness: { scope: :advisor_id }
end
