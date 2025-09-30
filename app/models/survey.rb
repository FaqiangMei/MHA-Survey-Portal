class Survey < ApplicationRecord
  validates :title, presence: true
  validates :semester, presence: true
  
  has_many :competencies, dependent: :destroy
  # Expose questions through competencies so views/controllers can access them directly
  has_many :questions, through: :competencies
  has_many :survey_responses, dependent: :destroy
  # convenience: students through survey_responses
  has_many :students, through: :survey_responses
end
