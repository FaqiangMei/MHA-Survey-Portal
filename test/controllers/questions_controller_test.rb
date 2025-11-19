require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
  @admin = users(:admin)
  sign_in @admin
  @category = categories(:clinical_skills)
  @question = questions(:fall_q1) rescue Question.create!(category: @category, question_text: "Existing?", question_type: "short_answer", question_order: 1)
  end

  test "index and show render successfully" do
    get questions_path
    assert_response :success

    get question_path(@question)
    assert_response :success
  end

  test "new and create success and failure" do
    get new_question_path
    assert_response :success

  post questions_path, params: { question: { category_id: @category.id, question_text: "What?", question_type: "short_answer", question_order: 1 } }
    assert_response :redirect

  # invalid create (missing question_text)
  post questions_path, params: { question: { category_id: @category.id, question_type: "short_answer" } }
    assert_response :unprocessable_entity
  end

  test "edit update and destroy" do
    get edit_question_path(@question)
    assert_response :success

    patch question_path(@question), params: { question: { question_text: "Changed?" } }
    assert_response :redirect

    # destroy
    delete question_path(@question)
    assert_response :redirect
  end
end
