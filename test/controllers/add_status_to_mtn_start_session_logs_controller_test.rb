require 'test_helper'

class AddStatusToMtnStartSessionLogsControllerTest < ActionController::TestCase
  test "should get status:boolean" do
    get :status:boolean
    assert_response :success
  end

end
