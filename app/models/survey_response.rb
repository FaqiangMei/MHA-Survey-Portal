class SurveyResponse < ApplicationRecord
  enum :status, {
    not_started: "not_started",
    in_progress: "in_progress",
    submitted: "submitted",
    under_review: "under_review",
    approved: "approved"
  }, prefix: true

  belongs_to :survey, optional: true
  belongs_to :student, optional: true
  belongs_to :advisor, optional: true

  # Scope and helpers for dashboards and reporting
  scope :for_student, ->(student_id) { where(student_id: student_id) }
  scope :pending, -> { where.not(status: statuses[:submitted]) }
  scope :completed, -> { where(status: statuses[:submitted]) }

  def self.pending_for_student(student_id)
    for_student(student_id).pending
  end

  def self.completed_for_student(student_id)
    for_student(student_id).completed
  end
end
