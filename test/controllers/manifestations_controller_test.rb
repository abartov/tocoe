require 'test_helper'

# test helper
class ManifestationsControllerTest < ActionController::TestCase
  test 'should get show' do
    get :show
    assert_response :success
  end

  test 'should get approve' do
    get :approve
    assert_response :success
  end
end
