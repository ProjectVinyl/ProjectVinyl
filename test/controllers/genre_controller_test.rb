require 'test_helper'

class GenreControllerTest < ActionController::TestCase
  test "should get view" do
    get :view
    assert_response :success
  end

end
