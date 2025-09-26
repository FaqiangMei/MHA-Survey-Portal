class Student < ApplicationRecord
                # ActiveRecord::Enum occasionally caused class-load errors in this
                # environment; to avoid that we expose a simple TRACKS constant instead
                # and avoid calling the `enum` macro here.
                TRACKS = { residential: 0, executive: 1 }

    belongs_to :advisor, optional: true
    has_many :survey_responses, foreign_key: :student_id
    has_many :surveys, through: :survey_responses

    # convenience methods
    def pending_survey_responses
        survey_responses.where.not(status: SurveyResponse.statuses[:submitted])
    end

    def completed_survey_responses
        survey_responses.where(status: SurveyResponse.statuses[:submitted])
    end
end
