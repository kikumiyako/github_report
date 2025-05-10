require "test_helper"

class GithubReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get github_reports_index_url
    assert_response :success
  end
end
