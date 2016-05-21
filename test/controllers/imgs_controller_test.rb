require 'test_helper'

class ImgsControllerTest < ActionController::TestCase
  test "should get avatar" do
    get :avatar
    assert_response :success
  end

end
