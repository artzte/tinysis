TinySIS::Application.routes.draw do
 	root to: "school#index"

 	# credit routes

  resources :credit do
    get '/students/:id/credits', action: 'credit_assignments'
    get '/credit/editor/:parent_type/:parent_id', action: 'editor'
    get '/credit/editor/:id', action: 'editor'
    get '/credit/combiner/:id', action: 'combiner', as: 'combine_credit_assignments_form'
    post '/credit/destroy/:id', action: 'destroy', as: 'destroy_credit_assignment'
    post '/credit/add/:parent_type/:parent_id', action: 'add'
    post '/credit/update/:id', action: 'update'
    post '/credit/admin_destroy/:id', action: 'admin_destroy', as: 'admin_destroy_credit_assignments'
    post '/credit/delete_credits', action: 'delete_credits', as: 'delete_credit_assignments'
    post '/credit/combine/:id', action: 'combine', as: 'combine_credit_assignments'
    post '/credit/approve/:id', action: 'approve'
    post '/credit/split/:id', action: 'split', as: 'split_credit_assignments'
  end

  # notes
  resources :note do
    post '/note/new/:notable_class/:notable_id', action: 'create'
    get '/note/:id/edit', action: 'edit', as: 'edit_note'
    post '/note/:id', action: 'update', as: 'update_note'
    post '/note/:id/revert', action: 'revert', as: 'revert_note'
    post '/note/:id/destroy', action: 'destroy', as: 'destroy_note'
    post '/note/:id/save', action: 'save', as: 'save_note'
  end

  # school controller
  get '/catalog', to: 'school#catalog'
  get '/about', to: 'school#about'
  get '/boom', to: 'school#boom'

  # attendance
  resources :attendance do

    get '/contracts/:id/attendance', action: 'index', as: 'attendance'
    get '/contracts/:id/attendance/:year/:month/:day', action: 'roll', as: 'roll'
    get '/attendance/pick_roll/:id/:meeting_id', action: 'pick_roll'
    get '/attendance/pick_roll/:id', action: 'pick_roll'
    get '/attendance/show_calendar/:id/:year/:month/:meeting_id', action: 'show_calendar'
    get '/attendance/show_calendar/:id/:year/:month', action: 'show_calendar'
    get '/attendance/show_calendar/:id', action: 'show_calendar'
    post '/attendance/update/:meeting_id/:enrollment_id/:participation', action: 'update', as: 'update_attendance'
    post '/attendance/:id/update_all', action: 'update_all', as: 'update_all_attendance'
    post '/attendance/delete_roll/:id', action: 'delete_roll', as: 'delete_attendance_roll'
    post '/attendance/meeting/:id', action: 'update_meeting', as: 'update_meeting'
  end

  # status
  resources :status do
    get '/status/contract', action: 'contract', as: 'contract_status_summary'
    get '/status/contract_detail/:id', action: 'contract_detail', as: 'contract_status_detail'
    get '/status/contract_report/:id', action: 'contract_report', as: 'contract_report'
    get '/status/coor', action: 'coor', as: 'coor_status_summary'
    get '/status/coor_detail/:id', action: 'coor_detail', as: 'coor_status_detail'
    get '/status/coor_report/:id', action: 'coor_report', as: 'coor_report'
  end
  #map.connect '/status/:action/:id', :controller => 'status'

  get '/my/account', to: 'account#edit', as: 'my_account'
  post '/my/account', to: 'account#update', as: 'update_my_account'
  get '/logout', to: 'account#logout', as: 'logout'
  get '/login', to: 'account#login', as: 'login'
  get '/reset', to: 'account#reset', as: 'reset_login'

  resources :reports do
    get '/reports/:action.:format'
  end

  resources :students do
    get '/students', action: 'index', as: 'students'
    get'/students/:id/status/:year', action: 'status', :year => /current|\d\d\d\d/, :defaults => { :year => 'current'}, as: 'student_status'
  end

  resources :learning_plan do
    get '/students/:id/learning/:year', action: 'show', :year => /current|\d\d\d\d/, :defaults => { :year => 'current'}, as: 'learning'
    get '/students/:id/learning/edit/:year', action: 'edit', :year => /current|\d\d\d\d/, :defaults => { :year => 'current'}, as: 'edit_learning'
    get '/students/:id/learning/:plan_id', action: 'update', as: 'update_learning'
  end

  resources :graduation_plan do
    get '/students/:id/graduation', action: 'index', as: 'graduation'
    get '/students/:id/graduation/unassign/:mapping_id', action: 'unassign', as: 'unassign_graduation_mapping'
    post '/students/:id/graduation/assign/:graduation_requirement_id/:credit_assignment_id', action: 'assign', as: 'assign_graduation_mapping'
    get '/students/:id/graduation/new/:requirement_id', action: 'new', as: 'new_graduation_mapping'
    get '/students/:id/graduation/edit/:mapping_id', action: 'edit', as: 'edit_graduation_mapping'
    get '/students/:id/graduation/show/:mapping_id', action: 'show', as: 'show_graduation_mapping'
    post '/students/:id/graduation/update/:mapping_id', action: 'update', as: 'update_graduation_mapping'
    post '/students/:id/graduation/create', action: 'create', as: 'create_graduation_mapping'
    post '/students/:id/graduation/destroy/:mapping_id', action: 'destroy', as: 'destroy_graduation_mapping'
    get '/students/:id/graduation/placeholders', action: 'placeholders', as: 'placeholder_credits'
    get '/students/:id/graduation/report', action: 'report', as: 'graduation_report'
  end

  resources :assignment do
    get '/contracts/:contract_id/student/:id', action: 'student', as: 'student_assignments'
    get '/contracts/:contract_id/assignments', action: 'index', as: 'assignments'
    get '/contracts/:contract_id/assignments/report', action: 'report', as: 'assignment_report'
    get '/contracts/:contract_id/enrollee/:id', action: 'enrollee', as: 'enrollee'
    get '/contracts/:contract_id/assignments/new', action: 'new', as: 'new_assignment'
    post '/contracts/:contract_id/assignments', action: 'create', as: 'create_assignment'
    get '/contracts/:contract_id/assignments/:id', action: 'edit', as: 'edit_assignment'
    post '/contracts/:contract_id/assignments/:id/destroy', action: 'destroy', as: 'destroy_assignment'
    post '/contracts/:contract_id/assignments/:id', action: 'update', as: 'update_assignment'
    get '/contracts/:contract_id/participant/:id', action: 'participant', as: 'contract_participant'
    post '/contracts/:contract_id/assignments/:id/record/:enrollment_id', action: 'record', as: 'record_assignment'
    post '/contracts/:contract_id/assignments/:id/feedback/:enrollment_id', action: 'feedback_edit', as: 'assignment_feedback'
  end

end
  # return a page not found for other routes

=begin
  map.with_options :controller => 'admin/ealrs', :conditions => {:method => :get} do |ealrs|
    ealrs.ealrs '/admin/ealrs', action: 'index'
    ealrs.new_ealr '/admin/ealrs/new/:category', action: 'new'
    ealrs.create_ealr '/admin/ealrs/create', action: 'create', :conditions => {:method => :post}
    ealrs.edit_ealr '/admin/ealrs/:id', action: 'edit'
    ealrs.update_ealr '/admin/ealrs/:id', action: 'update', :conditions => {:method => :post}
    ealrs.destroy_ealr '/admin/ealrs/:id/destroy', action: 'destroy', :conditions => {:method => :post}
  end
  map.with_options :controller => 'admin/accounts', :conditions => {:method => :get} do |account|
    account.accounts '/admin/accounts', action: 'index'
    account.new_account '/admin/accounts/new', action: 'new'
    account.edit_account '/admin/accounts/:id', action: 'edit'
    account.create_account '/admin/accounts', action: 'create', :conditions => { :method => :post}
    account.update_account '/admin/accounts/:id', action: 'update', :conditions => { :method => :post}
  end
  
  map.with_options :controller => 'admin/credits', :conditions => {:method => :get} do |credit|
    credit.credits '/admin/credits', action: 'index'
    credit.new_credit '/admin/credits/new', action: 'new'
    credit.edit_credit '/admin/credits/:id', action: 'edit'
    credit.create_credit '/admin/credits', action: 'create', :conditions => { :method => :post}
    credit.update_credit '/admin/credits/:id', action: 'update', :conditions => { :method => :post}
    credit.destroy_credit '/admin/credits/:id/destroy', action: 'destroy', :conditions => { :method => :post}
  end
  
  map.with_options :controller => 'admin/plans', :conditions => {:method => :get} do |plan|
    plan.plan_requirements '/admin/plans', action: 'index'
    plan.new_plan_requirement '/admin/plans/new/:type/:id', action: 'new', :requirements => {:type => /credit|general|service/}
    plan.edit_plan_requirement '/admin/plans/:id', action: 'edit'
    
    plan.connect '/admin/plans/sort', action: 'sort', :conditions => { :method => :post}
    plan.create_plan_requirement '/admin/plans/:type', action: 'create', :conditions => { :method => :post}, :requirements => {:type => /credit|general|service/}
    plan.update_plan_requirement '/admin/plans/:id', action: 'update', :conditions => { :method => :post}
    plan.destroy_plan_requirement '/admin/plans/:id/destroy', action: 'destroy', :conditions => { :method => :post}
  end
  
  map.with_options :controller => 'admin/enrollments', :conditions => {:method => :get} do |enrollment|
    enrollment.finalize_enrollments '/admin/enrollments', action: 'index'
    enrollment.finalize_enrollments_show '/admin/enrollments/:id/show', action: 'show'
    enrollment.finalize_enrollments_edit '/admin/enrollments/:id', action: 'edit'
    enrollment.finalize_enrollments_update '/admin/enrollments/:id', action: 'update', :conditions => {:method => :post}
  end
  
  map.with_options :controller => 'admin/credit_batches', :conditions => {:method => :get} do |batches|
    batches.credit_batches '/admin/credit_batches', action: 'index'
    batches.create_credit_batch '/admin/credit_batches', action: 'create', :conditions => {:method => :post}
    batches.credit_batch '/admin/credit_batches/:id', action: 'show'
  end

  map.with_options :controller => 'admin/reports', :conditions => {:method => :get} do |batches|
    batches.credit_batches '/admin/reports', action: 'index'
  end
  
  map.with_options :controller => 'admin/categories', :conditions => {:method => :get} do |category|
    category.categories '/admin/categories', action: 'index'
    category.new_category '/admin/categories/new', action: 'new'
    category.edit_category '/admin/categories/:id', action: 'edit'
    category.connect '/admin/categories/sort', action: 'sort', :conditions => { :method => :post}
    category.create_category '/admin/categories', action: 'create', :conditions => { :method => :post}
    category.update_category '/admin/categories/:id', action: 'update', :conditions => { :method => :post}
    category.destroy_category '/admin/categories/:id/destroy', action: 'destroy', :conditions => { :method => :post}
    category.connect '/admin/categories/:id/:group', :action=>'assign_group', :conditions => { :id => /^d+/, :group => /^d+/, :method => :post}
  end
  
  
  map.connect '*anything', :controller => 'school', action: 'unknown_request'
end

=end
