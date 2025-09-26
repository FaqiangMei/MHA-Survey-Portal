class SurveyResponse < ApplicationRecord
    belongs_to :student, optional: true
    belongs_to :advisor, optional: true
    belongs_to :survey, optional: true

        # Some environments have issues with ActiveRecord::Enum; define a simple
        # STATUS mapping and provide a .statuses method so existing code that
        # references SurveyResponse.statuses[:submitted] still works.
        STATUS = { not_started: 0, in_progress: 1, submitted: 2, under_review: 3, approved: 4 }

        def self.statuses
            STATUS
        end

        scope :for_student, ->(student_id) { where(student_id: student_id) }
        scope :pending_for_student, ->(student_id) { for_student(student_id).where.not(status: STATUS[:submitted]) }
        scope :completed_for_student, ->(student_id) { for_student(student_id).where(status: STATUS[:submitted]) }
end
