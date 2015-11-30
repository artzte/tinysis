require 'test_helper'

class Api::ContractsControllerTest < ActionController::TestCase
  setup do
    @api_contract = api_contracts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:api_contracts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create api_contract" do
    assert_difference('Api::Contract.count') do
      post :create, api_contract: {  }
    end

    assert_redirected_to api_contract_path(assigns(:api_contract))
  end

  test "should show api_contract" do
    get :show, id: @api_contract
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @api_contract
    assert_response :success
  end

  test "should update api_contract" do
    patch :update, id: @api_contract, api_contract: {  }
    assert_redirected_to api_contract_path(assigns(:api_contract))
  end

  test "should destroy api_contract" do
    assert_difference('Api::Contract.count', -1) do
      delete :destroy, id: @api_contract
    end

    assert_redirected_to api_contracts_path
  end
end
