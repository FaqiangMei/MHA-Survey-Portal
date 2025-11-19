require "test_helper"

class StudentProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @student_user = users(:student)
    sign_in @student_user
    @student = students(:student)
  end

  test "show and edit assign current student and advisors" do
    get student_profile_path
    assert_response :success

    get edit_student_profile_path
    assert_response :success
  end

  test "update success and failure" do
    # Failure: missing major (profile_completion requires major)
    patch student_profile_path, params: { student: { major: "" } }
    assert_response :unprocessable_entity

    # Success: provide major
    patch student_profile_path, params: { student: { major: "Computer Science" } }
    assert_response :redirect
    assert_redirected_to student_dashboard_path
  end
end
