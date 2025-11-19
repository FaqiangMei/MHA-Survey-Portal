require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "should get root" do
    get root_path
    assert_response :success
  end
  
  # ApplicationController is the base controller - main tests are in specific controller tests
end
