class AddQuestionToFeedbackFix < ActiveRecord::Migration[8.0]
  def change
    # Ensure we add the question_id column to the singular `feedback` table if missing.
    unless column_exists?(:feedback, :question_id)
      say "Adding question_id to feedback table"
      change_table :feedback do |t|
        t.references :question, foreign_key: { to_table: :questions }, index: true
      end
    else
      say "question_id already exists on feedback table; skipping"
    end
  end
end
