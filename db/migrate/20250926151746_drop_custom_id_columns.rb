class DropCustomIdColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :surveys, :survey_id, :integer
    remove_column :competencies, :competency_id, :integer
    remove_column :questions, :question_id, :integer
    remove_column :survey_responses, :surveyresponse_id, :integer
    remove_column :competency_responses, :competencyresponse_id, :integer
    remove_column :question_responses, :questionresponse_id, :integer
    remove_column :students, :student_id, :integer
    remove_column :advisors, :advisor_id, :integer
    remove_column :feedbacks, :feedback_id, :integer
    remove_column :evidence_uploads, :evidenceupload_id, :integer
  end
end
