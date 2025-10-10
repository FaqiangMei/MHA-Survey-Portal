class AddQuestionDependencies < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :depends_on_question_id, :bigint
    add_column :questions, :depends_on_value, :string

    add_index :questions, :depends_on_question_id
    add_foreign_key :questions, :questions, column: :depends_on_question_id, primary_key: :question_id, on_delete: :nullify
  end
end
