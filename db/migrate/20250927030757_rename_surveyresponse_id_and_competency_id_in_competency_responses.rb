class RenameSurveyresponseIdAndCompetencyIdInCompetencyResponses < ActiveRecord::Migration[8.0]
  def change
    rename_column :competency_responses, :surveyresponse_id, :survey_response_id
  end
end
