require "test_helper"

class AccountsIntegrationTest < ActionDispatch::IntegrationTest
  test "unauthenticated edit redirects to sign-in" do
    get edit_account_path
    assert_redirected_to new_user_session_path
  end

  test "authenticated user can edit and update account (success)" do
    user = users(:student)
    sign_in user

    get edit_account_path
    assert_response :success

    patch account_path, params: { user: { name: "New Name" } }
    assert_redirected_to edit_account_path
    assert_equal "Your account information has been updated.", flash[:notice]
    assert_equal "New Name", user.reload.name
  end

  test "authenticated user update failure renders edit with alert" do
    user = users(:student)
    sign_in user

    patch account_path, params: { user: { name: "" } }

    assert_response :unprocessable_entity
    assert_equal "Please correct the errors below.", flash[:alert]
  end
end
