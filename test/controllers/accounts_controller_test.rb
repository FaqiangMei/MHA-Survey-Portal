require "test_helper"

class AccountsControllerTest < ActionController::TestCase
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

  test "update success redirects with notice" do
    patch :update, params: { user: { name: "Updated Name" } }

    assert_redirected_to edit_account_path
    assert_equal "Your account information has been updated.", flash[:notice]
    @user.reload
    assert_equal "Updated Name", @user.name
  end

  test "update failure renders edit with alert and unprocessable_entity status" do
    # Provide an invalid name to trigger model validation failure
    patch :update, params: { user: { name: "" } }

  assert_response :unprocessable_entity
  # flash.now[:alert] should be present
  assert_equal "Please correct the errors below.", flash[:alert]
  end
end
