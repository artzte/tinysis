require File.dirname(__FILE__) + '/../test_helper'
require 'contract_categories_controller'

# Re-raise errors caught by the controller.
class ContractCategoriesController; def rescue_action(e) raise e end; end

class ContractCategoriesControllerTest < Test::Unit::TestCase
  def setup
    @controller = ContractCategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    login_as :admin

  end
  
  # non-admin user tried to hit the controller - he should get
  # logged out
  
  def test_get_without_privileges
    login_as :fester
    
    xhr :get, :edit
    
    # user should have been logged out
    assert_nil @response.session[:user_id]
    assert_match /unexpected/, @response.body
  end
  

  def test_edit_get_for_add
    xhr :get, :edit

    assert_template "contract_categories/form"
  end
  
  def test_edit_put_for_add
    
    assert_equal 8, Category.count
    xhr :post, :edit, {:category => {:name => 'Test', :statusable => "1", :public => "0"}}
    assert_equal 9, Category.count
    
    assert_template "contract_categories/_catalog"
  end
  
  def test_edit_put_for_edit
    @category = Category.find_by_name "science"
    
    assert_equal 8, Category.count
    xhr :post, :edit, {:id => @category.id, :category => {:name => 'Test', :statusable => "1", :public => "0"}}
    assert_equal 8, Category.count
    
    @category.reload
    
    assert_equal @category.name, 'Test'
    
    assert_template "contract_categories/_catalog"
  end
  
  def test_destroy_valid
    @category = Category.create(:name => 'to delete')
    
    assert_equal 9, Category.count

    xhr :post, :destroy, {:id => @category.id}
    
    assert_equal 8, Category.count
    assert_template "contract_categories/_catalog"
  end
  
  def test_destroy_refused_because_contracts
    @category = Category.find_by_name "Science"
    
    assert_equal 8, Category.count

    xhr :post, :destroy, {:id => @category.id}
    
    assert_equal 8, Category.count
    assert_match /cannot be deleted/, @response.body
  end
  
  def test_assign_group
    @category = Category.find_by_name "Science"
    
    xhr :post, :assign_group, {:category_id => @category.id, :group => 1000}
    
    @category.reload
    
    assert_equal 1000, @category.sequence
    assert_template "contract_categories/_catalog"
  end
  
  def test_arrange_groups
    xhr :post, :arrange_groups, {"contract_categories"=>["200", "100", "300"]}
    
    assert_template "contract_categories/_catalog"

    @category = Category.find_by_name "Homeroom"
    assert_equal 200, @category.sequence
    
    @category = Category.find_by_name "Seminar"
    assert_equal 100, @category.sequence
  end
  
end
