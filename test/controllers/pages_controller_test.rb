require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "about and faq are publicly accessible" do
    get about_path
    assert_response :success

    get faq_path
    assert_response :success
  end
end
