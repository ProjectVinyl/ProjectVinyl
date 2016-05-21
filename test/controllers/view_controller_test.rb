require 'test_helper'

class ViewControllerTest < ActionController::TestCase
  test "should get view" do
    get :view
    assert_response :success
  end

end
