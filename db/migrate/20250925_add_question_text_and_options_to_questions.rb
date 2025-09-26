class AddQuestionTextAndOptionsToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :question, :string unless column_exists?(:questions, :question)
    add_column :questions, :answer_options, :text unless column_exists?(:questions, :answer_options)
  end
end
