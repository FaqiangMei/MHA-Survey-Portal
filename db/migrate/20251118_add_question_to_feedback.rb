class AddQuestionToFeedback < ActiveRecord::Migration[8.0]
  def change
    change_table :feedback do |t|
      t.references :question, foreign_key: { to_table: :questions }, index: true
    end
    # Keep category_id for legacy records; new feedback will prefer question_id.
  end
end
