require "test_helper"

class StudentQuestionTest < ActiveSupport::TestCase
  test "drive url regex accepts Google Drive links and rejects others" do
    good = "https://drive.google.com/file/d/1abcdef/view?usp=sharing"
    bad = "https://example.com/not-drive"
    assert_match StudentQuestion::DRIVE_URL_REGEX, good
    refute_match StudentQuestion::DRIVE_URL_REGEX, bad
  end

  test "creating and updating a student question persists answers" do
    student = students(:student)
    q = questions(:fall_q1)
    sq = StudentQuestion.find_or_initialize_by(student_id: student.student_id, question_id: q.id)
    sq.answer = "Test answer"
    sq.save!
    assert_equal "Test answer", StudentQuestion.find_by(id: sq.id).answer
  end
end
