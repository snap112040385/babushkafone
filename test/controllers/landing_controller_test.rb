require "test_helper"

class LandingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get landing_index_url
    assert_response :success
  end

  test "should get sasha" do
    get landing_sasha_url
    assert_response :success
  end
end
