require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  test "should get search" do
    get :search
    assert_response :success
  end

  test "should get details" do
    get :details
    assert_response :success
  end

  test "should get browse" do
    get :browse
    assert_response :success
  end

  test "should get savetoc" do
    get :savetoc
    assert_response :success
  end

end
