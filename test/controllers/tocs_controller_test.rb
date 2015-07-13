require 'test_helper'

class TocsControllerTest < ActionController::TestCase
  setup do
    @toc = tocs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tocs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create toc" do
    assert_difference('Toc.count') do
      post :create, toc: { book_uri: @toc.book_uri, comments: @toc.comments, contributor_id: @toc.contributor_id, reviewer_id: @toc.reviewer_id, status: @toc.status, toc_body: @toc.toc_body }
    end

    assert_redirected_to toc_path(assigns(:toc))
  end

  test "should show toc" do
    get :show, id: @toc
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @toc
    assert_response :success
  end

  test "should update toc" do
    patch :update, id: @toc, toc: { book_uri: @toc.book_uri, comments: @toc.comments, contributor_id: @toc.contributor_id, reviewer_id: @toc.reviewer_id, status: @toc.status, toc_body: @toc.toc_body }
    assert_redirected_to toc_path(assigns(:toc))
  end

  test "should destroy toc" do
    assert_difference('Toc.count', -1) do
      delete :destroy, id: @toc
    end

    assert_redirected_to tocs_path
  end
end
