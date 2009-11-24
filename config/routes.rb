ActionController::Routing::Routes.draw do |map|

 	map.home '', :controller => "school"

 	# credit routes
 	
  map.with_options :controller => 'credit', :conditions => {:method => :get} do |credit|
    credit.credit_assignments '/students/:id/credits', :action => 'index'
    credit.my_credit_assignments '/my/credits', :action => 'index'
    credit.connect '/credit/editor/:parent_type/:parent_id', :action => 'editor'
    credit.connect '/credit/editor/:id', :action => 'editor'
    credit.combine_credit_assignments_form '/credit/combiner/:id', :action => 'combiner'
    credit.with_options :conditions => {:method => :post} do |pc|
      pc.connect '/credit/add/:parent_type/:parent_id', :action => 'add'
      pc.connect '/credit/update/:id', :action => 'update'
      pc.admin_destroy_credit_assignments '/credit/admin_destroy/:id', :action => 'admin_destroy'
      pc.delete_credit_assignments '/credit/delete_credits', :action => 'delete_credits'
      pc.combine_credit_assignments '/credit/combine/:id', :action => 'combine'
      pc.connect '/credit/approve/:id', :action => 'approve'
      pc.split_credit_assignments '/credit/split/:id', :action => 'split'
    end
  end

  # map.connect '/note/new/:notable_class/:notable_id', :controller => 'note', :action => 'new'
  # map.connect '/note/:action/:id', :controller => 'note'

  # notes
  map.with_options :controller => 'note', :conditions => {:method => :get} do |note|
    note.create_note '/note/new/:notable_class/:notable_id', :action => 'create', :conditions => {:method => :post}
    note.edit_note '/note/:id/edit', :action => 'edit'
    note.update_note '/note/:id', :action => 'update', :conditions => {:method => :post}
    note.revert_note '/note/:id/revert', :action => 'revert', :conditions => {:method => :post}
    note.destroy_note '/note/:id/destroy', :action => 'destroy', :conditions => {:method => :post}
    note.save_note '/note/:id/save', :action => 'save', :conditions => {:method => :post}
  end

  # school controller
  map.with_options :controller => 'school', :conditions => {:method => :get} do |s|
    s.catalog '/catalog', :action => 'catalog'
    s.about '/about', :action => 'about'
  end

  # attendance routes
  
  map.with_options :controller => 'attendance', :conditions => {:method => :get} do |att|
  
    att.attendance '/contracts/:id/attendance/:meeting_id', :action => 'index'
    att.attendance '/contracts/:id/attendance', :action => 'index'
    att.roll '/contracts/:id/attendance/:year/:month/:day', :controller=>'attendance', :action=>'roll'

    att.connect '/attendance/pick_roll/:id/:meeting_id', :action => 'pick_roll'
    att.connect '/attendance/pick_roll/:id', :action => 'pick_roll'
    att.connect '/attendance/show_calendar/:id/:year/:month/:meeting_id', :action => 'show_calendar'
    att.connect '/attendance/show_calendar/:id/:year/:month', :action => 'show_calendar'
    att.connect '/attendance/show_calendar/:id', :action => 'show_calendar'
    att.connect '/attendance/update/:id/:participation', :action => 'update', :conditions => {:method => :post}
    att.connect '/attendance/update_all/:id/:participation', :action => 'update_all', :conditions => {:method => :post}
    att.connect '/attendance/delete_roll/:id', :action => 'delete_roll', :conditions => {:method => :post}
  end
  
  map.with_options :controller => 'account' do |account|
    account.my_account '/my/account', :action => 'edit', :conditions => {:method => :get}
    account.update_my_account '/my/account', :action => 'update', :conditions => {:method => :post}
    account.logout '/logout', :action => 'logout'
    account.login '/login', :action => 'login'
    account.reset_login '/reset', :action => 'reset'
  end
  
  map.with_options :controller => 'admin/accounts', :conditions => {:method => :get} do |account|
    account.accounts '/admin/accounts', :action => 'index'
    account.new_account '/admin/accounts/new', :action => 'new'
    account.edit_account '/admin/accounts/:id', :action => 'edit'
    account.create_account '/admin/accounts', :action => 'create', :conditions => { :method => :post}
    account.update_account '/admin/accounts/:id', :action => 'update', :conditions => { :method => :post}
  end
  
  map.with_options :controller => 'admin/credits', :conditions => {:method => :get} do |credit|
    credit.credits '/admin/credits', :action => 'index'
    credit.new_credit '/admin/credits/new', :action => 'new'
    credit.edit_credit '/admin/credits/:id', :action => 'edit'
    credit.create_credit '/admin/credits', :action => 'create', :conditions => { :method => :post}
    credit.update_credit '/admin/credits/:id', :action => 'update', :conditions => { :method => :post}
    credit.destroy_credit '/admin/credits/:id/destroy', :action => 'destroy', :conditions => { :method => :post}
  end
  
  map.with_options :controller => 'admin/learning_plans', :conditions => {:method => :get} do |learning_plan|
    learning_plan.learning_plan_goals '/admin/learning_plans', :action => 'index'
    learning_plan.new_learning_plan_goal '/admin/learning_plans/new', :action => 'new'
    learning_plan.edit_learning_plan_goal '/admin/learning_plans/:id', :action => 'edit'
    learning_plan.connect '/admin/learning_plans/sort', :action => 'sort', :conditions => { :method => :post}
    learning_plan.create_learning_plan_goal '/admin/learning_plans', :action => 'create', :conditions => { :method => :post}
    learning_plan.update_learning_plan_goal '/admin/learning_plans/:id', :action => 'update', :conditions => { :method => :post}
    learning_plan.destroy_learning_plan_goal '/admin/learning_plans/:id/destroy', :action => 'destroy', :conditions => { :method => :post}
  end
  
  map.with_options :controller => 'admin/plans', :conditions => {:method => :get} do |plan|
    plan.plan_requirements '/admin/plans', :action => 'index'
    plan.new_plan_requirement '/admin/plans/new/:type/:id', :action => 'new', :requirements => {:type => /credit|general|service/}
    plan.edit_plan_requirement '/admin/plans/:id', :action => 'edit'
    
    plan.connect '/admin/plans/sort', :action => 'sort', :conditions => { :method => :post}
    plan.create_plan_requirement '/admin/plans/:type', :action => 'create', :conditions => { :method => :post}, :requirements => {:type => /credit|general|service/}
    plan.update_plan_requirement '/admin/plans/:id', :action => 'update', :conditions => { :method => :post}
    plan.destroy_plan_requirement '/admin/plans/:id/destroy', :action => 'destroy', :conditions => { :method => :post}
  end
  
  map.with_options :controller => 'admin/enrollments', :conditions => {:method => :get} do |enrollment|
    enrollment.finalize_enrollments '/admin/enrollments', :action => 'index'
    enrollment.finalize_enrollments_show '/admin/enrollments/:id/show', :action => 'show'
    enrollment.finalize_enrollments_edit '/admin/enrollments/:id', :action => 'edit'
    enrollment.finalize_enrollments_update '/admin/enrollments/:id', :action => 'update', :conditions => {:method => :post}
  end
  
  map.with_options :controller => 'admin/credit_batches', :conditions => {:method => :get} do |batches|
    batches.credit_batches '/admin/credit_batches', :action => 'index'
    batches.create_credit_batch '/admin/credit_batches', :action => 'create', :conditions => {:method => :post}
    batches.credit_batch '/admin/credit_batches/:id', :action => 'show'
  end

  map.with_options :controller => 'admin/categories', :conditions => {:method => :get} do |category|
    category.categories '/admin/categories', :action => 'index'
    category.new_category '/admin/categories/new', :action => 'new'
    category.edit_category '/admin/categories/:id', :action => 'edit'
    category.connect '/admin/categories/sort', :action => 'sort', :conditions => { :method => :post}
    category.create_category '/admin/categories', :action => 'create', :conditions => { :method => :post}
    category.update_category '/admin/categories/:id', :action => 'update', :conditions => { :method => :post}
    category.destroy_category '/admin/categories/:id/destroy', :action => 'destroy', :conditions => { :method => :post}
    category.connect '/admin/categories/:id/:group', :action=>'assign_group', :conditions => { :id => /^d+/, :group => /^d+/, :method => :post}
  end
  
  
  map.with_options :controller => 'students', :conditions => {:method => :get} do |s|
    s.students '/students', :action => 'index'
    s.formatted_students '/students.:format', :action => 'index'
    s.my_status '/my', :action => 'my', :conditions => {:method => :get}
    s.student_status '/students/:id/status/:year', :action => 'status', :year => /current|\d\d\d\d/, :defaults => { :year => 'current'}
    s.my_student_status '/my/status', :action => 'status'
  end
  
  map.with_options :controller => 'learning_plan', :conditions => {:method => :get} do |s|
    s.learning '/students/:id/learning/:year', :action => 'show', :year => /current|\d\d\d\d/, :defaults => { :year => 'current'}
    s.my_learning '/my/learning', :action => 'show'
    s.edit_learning '/students/:id/learning/edit/:year', :action => 'edit', :year => /current|\d\d\d\d/, :defaults => { :year => 'current'}
    s.update_learning '/students/:id/learning/:plan_id', :action => 'update', :conditions => {:method => :post}
  end
    
  map.with_options :controller => 'graduation_plan', :conditions => {:method => :get} do |g|
    g.graduation '/students/:id/graduation', :action => 'index'
    g.my_graduation '/my/graduation', :action => 'report'
    g.unassign_graduation_mapping '/students/:id/graduation/unassign/:mapping_id', :action => 'unassign', :conditions => {:method => :post}
    g.assign_graduation_mapping '/students/:id/graduation/assign/:graduation_requirement_id/:credit_assignment_id', :action => 'assign', :conditions => {:method => :post}
    g.new_graduation_mapping '/students/:id/graduation/new/:requirement_id', :action => 'new'
    g.edit_graduation_mapping '/students/:id/graduation/edit/:mapping_id', :action => 'edit'
    g.show_graduation_mapping '/students/:id/graduation/show/:mapping_id', :action => 'show'
    g.update_graduation_mapping '/students/:id/graduation/update/:mapping_id', :action => 'update', :conditions => {:method => :post}
    g.create_graduation_mapping '/students/:id/graduation/create', :action => 'create', :conditions => {:method => :post}
    g.destroy_graduation_mapping '/students/:id/graduation/destroy/:mapping_id', :action => 'destroy', :conditions => {:method => :post}
    g.placeholder_credits '/students/:id/graduation/placeholders', :action => 'placeholders'
    g.graduation_report '/students/:id/graduation/report', :action => 'report'
  end
  
  map.with_options :controller => 'assignment', :conditions => {:method => :get} do |a|
    a.student_assignments '/contracts/:contract_id/student/:id', :action => 'student'
    a.assignments '/contracts/:contract_id/assignments', :action => 'index'
    a.assignment_report '/contracts/:contract_id/assignments/report', :action => 'report'
    a.enrollee '/contracts/:contract_id/enrollee/:id', :action => 'enrollee'
    a.new_assignment '/contracts/:contract_id/assignments/new', :action => 'new'
    a.create_assignment '/contracts/:contract_id/assignments', :action => 'create', :conditions => {:method => :post}
    a.edit_assignment '/contracts/:contract_id/assignments/:id', :action => 'edit'
    a.destroy_assignment '/contracts/:contract_id/assignments/:id/destroy', :action => 'destroy', :conditions => {:method => :post}
    a.update_assignment '/contracts/:contract_id/assignments/:id', :action => 'update', :conditions => {:method => :post}
    a.contract_participant '/contracts/:contract_id/participant/:id', :action => 'participant'
    a.record_assignment '/contracts/:contract_id/assignments/:id/record/:enrollment_id', :action => 'record', :conditions => {:method => :post}
    a.assignment_feedback '/contracts/:contract_id/assignments/:id/feedback/:enrollment_id', :action => 'feedback_edit', :conditions => {:method => :post}
  end

  map.connect '/assets/gradesheet/:filename', :filename => /ah_\d+p?\.gif/, :conditions => {:method => :get}, :controller => 'assignment', :action => 'header'
  
  
  map.with_options :controller => 'enrollment', :conditions => {:method => :get} do |e|
    e.enrollments '/contracts/:id/enrollments', :action => 'index'
    e.reset_credits '/contracts/:id/enrollments/reset', :action => 'reset', :conditions => {:method => :post}
    e.update_enrollment_status '/enrollments/:id/:command', :action => 'update', :conditions => {:method => :post, :id => /\d+/}
    e.new_enrollments '/contracts/:id/enrollments/new', :action => 'new'
    e.create_enrollments '/contracts/:id/enrollments/create', :action => 'create', :conditions => {:method => :post}
  end
  
  map.with_options :controller => 'contract', :conditions => {:method => :get} do |c|
    c.contracts '/contracts', :action => 'index'
    c.new_contract '/contracts/new', :action => 'new'
    c.create_contract '/contracts', :action => 'create', :conditions => {:method => :post}
    c.contract '/contracts/:id', :action => 'show'
    c.set_contract_credits '/contracts/:id/credits', :action => 'credits'
    c.edit_contract '/contracts/:id/edit/:section', :action => 'edit', :section => 'summary'
    c.cancel_edit_contract '/contracts/:id/cancel/:section', :action => 'cancel', :section => 'summary'
    c.destroy_contract '/contracts/:id/destroy', :action => 'destroy', :conditions => {:method => :post}
    c.update_contract '/contracts/:id/:section', :action => 'update', :conditions => {:method => :post}, :section => 'summary'
  end
  map.connect '/contract/:action/:id', :controller => 'contract'
  
  map.connect '/credit/:action/:id', :controller => 'credit'
  

  map.connect '/learning_plans/:action/:id', :controller => 'learning_plans'
  
  map.with_options :controller => 'admin/terms', :conditions => {:method => :get} do |terms|
    terms.terms '/admin/terms', :action => 'index'
    terms.new_term '/admin/terms/new', :action => 'new'
    terms.edit_term '/admin/terms/:id/edit', :action => 'edit'
    terms.show_term '/admin/terms/:id', :action => 'show'
    terms.create_term '/admin/terms/create', :action => 'create', :conditions => {:method => :post}
    terms.update_term '/admin/terms/:id', :action => 'update', :conditions => {:method => :post }
    terms.destroy_term '/admin/terms/:id/destroy', :action => 'destroy', :conditions => {:method => :post}
  end
  
  map.with_options :controller => 'admin/periods', :conditions => {:method => :get} do |periods|
    periods.periods '/admin/periods', :action => 'show'
    periods.edit_periods '/admin/periods/edit', :action => 'edit'
    periods.update_periods '/admin/periods', :action => 'update', :conditions => {:method => :post }
  end
  
  map.with_options :controller => 'admin/settings', :conditions => {:method => :get} do |settings|
    settings.settings '/admin/settings', :action => 'index'
    settings.edit_settings '/admin/settings/edit', :action => 'edit'
    settings.show_settings '/admin/settings/show', :action => 'show'
    settings.update_settings '/admin/settings', :action => 'update', :conditions => {:method => :post}
  end

  map.with_options :controller => 'admin/ealrs', :conditions => {:method => :get} do |ealrs|
    ealrs.ealrs '/admin/ealrs', :action => 'index'
    ealrs.new_ealr '/admin/ealrs/new/:category', :action => 'new'
    ealrs.create_ealr '/admin/ealrs/create', :action => 'create', :conditions => {:method => :post}
    ealrs.edit_ealr '/admin/ealrs/:id', :action => 'edit'
    ealrs.update_ealr '/admin/ealrs/:id', :action => 'update', :conditions => {:method => :post}
    ealrs.destroy_ealr '/admin/ealrs/:id/destroy', :action => 'destroy', :conditions => {:method => :post}
  end
  
  map.with_options :controller => 'status', :conditions => {:method => :get} do |e|
    e.contract_status_summary '/status/contract', :action => 'contract'
    e.contract_status_detail '/status/contract_detail/:id', :action => 'contract_detail'
    e.contract_report '/status/contract_report/:id', :action => 'contract_report'
    e.coor_status_summary '/status/coor', :action => 'coor'
    e.coor_status_detail '/status/coor_detail/:id', :action => 'coor_detail'
    e.coor_report '/status/coor_report/:id', :action => 'coor_report'
  end
  map.connect '/status/:action/:id', :controller => 'status'
  
  # return a page not found for other routes
  
  map.connect '*anything', :controller => 'school', :action => 'unknown_request'
end
