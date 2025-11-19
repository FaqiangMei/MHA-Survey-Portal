require "test_helper"

class EvidenceControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:student)
    sign_in @user
  end

  test "returns invalid_url for non-drive link" do
    get evidence_check_access_path, params: { url: "https://example.com/not-a-drive" }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "invalid_url", json["reason"]
  end

  test "returns ok and accessible when HTTP returns 200 (stubbed)" do
    # Stub Net::HTTP.new to return an object that responds to request
    fake_response = Struct.new(:code) do
      def [](k)
        nil
      end
      def is_a?(cls)
        false
      end
    end

    Net::HTTP.stub :new, ->(_host, _port) {
      obj = Object.new
      def obj.use_ssl=(_); end
      def obj.open_timeout=(_); end
      def obj.read_timeout=(_); end
      def obj.request(_req)
        # Simulate a successful 200 response
        Struct.new(:code) do
          def [](k) nil; end
          def is_a?(cls) false; end
          def code; "200"; end
        end.new
      end
      obj
    } do
  drive_url = "https://docs.google.com/document/d/12345"
  get evidence_check_access_path, params: { url: drive_url }, as: :json
      assert_response :success
      json = JSON.parse(response.body)
      assert_equal true, json["ok"]
      assert_equal true, json["accessible"]
      assert_equal 200, json["status"]
    end
  end

  test "returns forbidden when HTTP returns 403 (stubbed)" do
    Net::HTTP.stub :new, ->(_host, _port) {
      obj = Object.new
      def obj.use_ssl=(_); end
      def obj.open_timeout=(_); end
      def obj.read_timeout=(_); end
      def obj.request(_req)
        Struct.new(:code) do
          def [](k) nil; end
          def is_a?(cls) false; end
          def code; "403"; end
        end.new
      end
      obj
    } do
      drive_url = "https://drive.google.com/file/d/abc"
      get evidence_check_access_path, params: { url: drive_url }, as: :json
      assert_response :success
      json = JSON.parse(response.body)
      assert_equal true, json["ok"]
      assert_equal false, json["accessible"]
      assert_equal 403, json["status"]
      assert_equal "forbidden", json["reason"]
    end
  end

  test "falls back to GET when HEAD returns 405 (method not allowed)" do
    Net::HTTP.stub :new, ->(_host, _port) {
      obj = Object.new
      def obj.use_ssl=(_); end
      def obj.open_timeout=(_); end
      def obj.read_timeout=(_); end
      def obj.request(req)
        # If it's a HEAD request, return 405; otherwise return 200
        if req.is_a?(Net::HTTP::Head)
          Struct.new(:code) do
            def [](k) nil; end
            def is_a?(cls); cls == Net::HTTPMethodNotAllowed; end
            def code; "405"; end
          end.new
        else
          Struct.new(:code) do
            def [](k) nil; end
            def is_a?(cls) false; end
            def code; "200"; end
          end.new
        end
      end
      obj
    } do
      drive_url = "https://docs.google.com/document/d/12345"
      get evidence_check_access_path, params: { url: drive_url }, as: :json
      assert_response :success
      json = JSON.parse(response.body)
      assert_equal true, json["ok"]
      assert_equal true, json["accessible"]
      assert_equal 200, json["status"]
    end
  end

  test "follows redirects when HEAD returns a redirection with Location" do
    call_count = 0
    Net::HTTP.stub :new, ->(_host, _port) {
      obj = Object.new
      def obj.use_ssl=(_); end
      def obj.open_timeout=(_); end
      def obj.read_timeout=(_); end
      def obj.request(_req)
        # rely on closure-captured variable via binding
        Thread.current[:evidence_calls] ||= 0
        Thread.current[:evidence_calls] += 1
        if Thread.current[:evidence_calls] == 1
          # first call: redirect
          Struct.new(:code) do
            def [](k); k == "location" ? "https://docs.google.com/document/d/redirected" : nil; end
            def is_a?(cls); cls == Net::HTTPRedirection; end
            def code; "302"; end
          end.new
        else
          # second call: OK
          Struct.new(:code) do
            def [](k) nil; end
            def is_a?(cls) false; end
            def code; "200"; end
          end.new
        end
      end
      obj
    } do
      # ensure thread-local counter is fresh
      Thread.current[:evidence_calls] = 0
      drive_url = "https://docs.google.com/document/d/12345"
      get evidence_check_access_path, params: { url: drive_url }, as: :json
      assert_response :success
      json = JSON.parse(response.body)
      assert_equal true, json["ok"]
      assert_equal true, json["accessible"]
      assert_equal 200, json["status"]
    end
  end

  test "returns network_error when underlying HTTP raises" do
    Net::HTTP.stub :new, ->(_host, _port) { raise StandardError.new("boom") } do
      drive_url = "https://docs.google.com/document/d/12345"
      get evidence_check_access_path, params: { url: drive_url }, as: :json
      assert_response :success
      json = JSON.parse(response.body)
      assert_equal false, json["ok"]
      assert_equal false, json["accessible"]
      assert_equal "network_error", json["reason"]
    end
  end
end
