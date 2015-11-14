module TinyTabs
  # The tab setup consists of two pieces. One describes the privileges, the other 
  # Create a hash that indicates which toolbar items to render
  # Returned hash has keys set to TRUE if that main item exists
  # If the main item is current its value is an array indicating
  # subtab items that are active
  
  def setup_tabs
  
    tab_data = {
      :order => [:school, :status, :contracts, :students, :my, :admin, :settings],
      
      :school => {
        :path => '/',
        :title => AppConfig.app_organization_shortname,
        :tabs => {
          :index => {:title => 'Welcome', :path => "/"},
          :catalog => {:title => 'Course Catalog', :path => "/catalog"},
          :login => {:if => :logged_out?, :title => 'Log In', :path => "/login"},
          },
        :order => [:index, :catalog, :login]
      },
      
      :status => {
        :privilege => User::PRIVILEGE_STAFF,
        :tabs => {
          :index => {:title => 'My Status', :path => "/status"},
          :contract => {:title => 'Contract Status', :path => "/status/contract"},
          :coor => {:title => "#{AppConfig.app_organization_homeroom_name} Status", :path => "/status/coor"},
          :account => { :title => 'My Account', :path => "/my/account" },
          },
        :order => [:index, :contract, :coor, :account]
      },
      
      :my => {
        :title => 'My Stuff',
        :path => '/my',
        :if => :student_user?,
        :tabs => {
          :summary => { :path => "/my" },
          :schedule => { :path => "/my/schedule" },
          :status => { :path => "/my/status" },
          :credits => { :path => "/my/credits" },
          :learning_plan => { :path => "/my/plan" },
          :graduation_worksheet => { :path => "/my/graduation" },
          :account => {:path => '/my/account' }
          },
          :order => [:summary, :schedule, :status, :credits, :learning_plan, :graduation_worksheet, :account]
      },

      :contracts => {
        :privilege => User::PRIVILEGE_STUDENT,
        :title => 'Contracts',
        :tabs => {
          :index => {:title => 'Contracts', :path => "/contracts" },
          :new => { :title => 'New Contract', :path => "/contracts/new", :if => :new_contract? },
          :show => { :if => :contract, :title => 'Syllabus', :path => "/contracts/%c"},
          :enrollments => { :privilege => User::PRIVILEGE_STAFF, :if => :contract, :title => 'Enrollment/Credits', :path => "/contracts/%c/enrollments" },
          :assignments => { :if => [:contract, :viewable?], :privilege => User::PRIVILEGE_STAFF, :path => "/contracts/%c/assignments" },
          :participant => { :title => 'My Contract', :if => [:contract, :enrolled_user?], :path => "/contracts/%c/participant" },
          :attendance => { :if => :contract, :privilege => User::PRIVILEGE_STAFF, :path => "/contracts/%c/attendance" },
        },
        :order => [:index, :new, :show, :enrollments, :assignments, :attendance, :participant]
      },
      
      :students => {
        :privilege => User::PRIVILEGE_STAFF,
        :title => 'Students',
        :tabs => {
          :index => { :path => "/students" },
          :status => { :if => :student, :path => "/students/%s/status" },
          :learning => { :if => :student, :path => "/students/%s/learning" },
          :credits => { :if => :student, :path => "/students/%s/credits" },
          :graduation => { :if => :student, :path => "/students/%s/graduation" },
        },
        :order => [:index, :status, :learning, :credits, :graduation]
      },
        
      :admin => {
          :privilege => User::PRIVILEGE_ADMIN,
          :path => '/admin/accounts',
          :tabs => {
            :accounts => { :path => '/admin/accounts'},
            :enrollments => { :path => '/admin/enrollments'},
            :credit_batches => { :path => '/admin/credit_batches'},
            :reports => { :path => '/admin/reports'},
          },
          :order => [:accounts, :enrollments, :credit_batches, :reports]
        },
        
      :settings => {
          :privilege => User::PRIVILEGE_ADMIN,
          :path => '/admin/settings',
          :tabs => {
            :index => { :path => '/admin/settings' },
            :credits => { :path => '/admin/credits' },
            :terms => { :path => '/admin/terms' },
            :periods => { :path => '/admin/periods' },
            :learning_plans => { :path => '/admin/learning_plans', :title => 'Learning Plans' },
            :plans => { :path => '/admin/plans', :title => 'Graduation Requirements' },
            :categories => { :path => '/admin/categories' },
            :ealrs => { :path => '/admin/ealrs' },
          },
          :order => [:index, :terms, :periods, :credits, :plans, :learning_plans, :categories, :ealrs]
        },
    }
  
    # Tab settings normally are the controller/action pair symbolized. This can
    # be overridden on a specific action that might hide under another action's tab.
    
    @cur_tab ||= {}
    @cur_tab[:tab1] ||= controller.controller_name.to_sym
    @cur_tab[:tab2] ||= controller.action_name.to_sym

    @tabs = []
    @subtabs = []
    
    tab_data[:order].each do |k|

      tab = tab_data[k]
      
      # reject the top-level tab if user is not privileged
      next unless privileged_for? tab

      tab[:path] ||= "/#{k.to_s}"
      tab[:title] ||= k.to_s.humanize
      
      # Add the tab to the list
      @tabs << tab
      
      # If current tab, scan the subtabs and add
      if @cur_tab[:tab1]==k
        @tab1 = tab

        tab[:order].each do |l|

          subtab = tab[:tabs][l]
          
          raise ArgumentError, "Subtab #{l} not found" unless subtab

          next unless privileged_for? subtab

          subtab[:title] ||= l.to_s.humanize

          @tab2 = subtab if l==@cur_tab[:tab2]

          @subtabs << subtab
        end
      end
    end
    
    raise ArgumentError, "Tab 1 not found from #{@cur_tab.inspect}" unless @tab1
    raise ArgumentError, "Tab 2 not found from #{@cur_tab.inspect}" unless @tab2
    
  end
  
  # returns true if the logged in user should see this tab

  def privileged_for? tab
    return false if tab[:privilege] && (@user.nil? || tab[:privilege] > @user.privilege)
    
    return true unless tab[:if]
    
    tab[:if] = [tab[:if]] unless tab[:if].is_a? Array
    
    privileged = true
    tab[:if].each do |i|
      case i
      when :contract
        return false if @contract.nil? || @contract.new_record?
      when :student
        return false if @student.nil?
      when nil
      else
        return false unless self.send(i)
      end
    end
    return true    

  end
  
  # Provides a title for a tab based on tab symbol name or the title
  def tab_title tab
    tab[:title]||tab[:tab].to_s.humanize
  end
  
  # Translates the tab url, passing in the contract/student ID as necessary
  def tab_url tab
    tab[:path].gsub(/%(\w)/) {|s|tab_url_translate(s, $1)}
  end
  
  def tab_url_translate(s, code)
    case code
    when 'c'
      @contract.id.to_s
    when 's'
      @student.id.to_s
    when 'u'
      @user.id.to_s
    else
      raise ArgumentError, "Unknown tab URL substition code #{s}"
    end
  end
  
  def student_user?
    @user && @user.privilege==User::PRIVILEGE_STUDENT
  end
  
  def logged_out?
    @user.nil?
  end
  
  def new_contract?
    @contract && @contract.new_record?
  end
  
  def enrolled_user?
    @contract && @user && @user.enrolled_in?(@contract)
  end
  
  def editable?
    @privs[:edit]
  end
  
  def viewable?
    @privs[:view]
  end
  
  def viewable_not_editable?
    @privs[:view] && !@privs[:edit]
  end
  
  

end