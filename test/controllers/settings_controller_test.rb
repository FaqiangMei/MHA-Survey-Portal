require "test_helper"

class SettingsControllerTest < ActionController::TestCase
  setup do
    @user = users(:student)
    sign_in @user
  end

  test "edit assigns current user" do
    get :edit
    assert_response :success
    assigned = @controller.instance_variable_get(:@user)
    assert_equal @user, assigned
  end

  test "update success redirects back or to root with notice" do
    # Ensure referer fallback path branch is exercised
    @request.env["HTTP_REFERER"] = nil

    patch :update, params: { user: { language: "en", notifications_enabled: true, text_scale_percent: 100 } }

    assert_redirected_to root_path
    assert_equal "Settings updated successfully.", flash[:notice]
    # reload to confirm persisted changes
    @user.reload
    assert_equal "en", @user.language
    assert_equal true, @user.notifications_enabled
    assert_equal 100, @user.text_scale_percent
  end

  test "update failure renders edit with alert" do
    # Provide an invalid value to trigger validation failure (text_scale_percent must be >= 100)
    patch :update, params: { user: { text_scale_percent: 50 } }

    assert_response :unprocessable_entity
    assert_equal "Please correct the errors below.", flash[:alert]
  end
end
