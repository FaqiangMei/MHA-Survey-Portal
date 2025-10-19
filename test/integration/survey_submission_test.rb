require "test_helper"

class SurveySubmissionTest < ActionDispatch::IntegrationTest
  setup do
    @student_user = users(:student)
    @student = students(:student)
    @advisor = advisors(:advisor)

    @survey = Survey.new(title: "Integration Survey", semester: "Fall 2025")
    category = @survey.categories.build(name: "General", description: "Confidence")
    @question = category.questions.build(
      question_text: "How confident are you?",
      question_order: 1,
      question_type: "short_answer",
      is_required: true
    )
    @survey.save!

    sign_in @student_user
  end

  test "student can submit survey responses" do
    post submit_survey_path(@survey), params: {
      answers: {
        @question.id => "Confident"
      }
    }

    expected_response_id = "#{@student.student_id}-#{@survey.id}"
    assert_redirected_to survey_response_path(expected_response_id)

    student_question = StudentQuestion.find_by(student_id: @student.student_id, question_id: @question.id)
    assert_not_nil student_question
    assert_equal "Confident", student_question.answer
  end
end
