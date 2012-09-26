module Admin::AccountsHelper
  include SearchHelper
  include NoteHelper

  def privilege_options all=false
    options = [User::PRIVILEGE_STUDENT, User::PRIVILEGE_STAFF, User::PRIVILEGE_ADMIN].collect{|o| [User::PRIVILEGE_NAMES[o], o]}
    options = [['Staff and students',0]]+options if all
    options
  end
  def login_options
    options=[User::LOGIN_NONE, User::LOGIN_REQUESTED, User::LOGIN_ALLOWED].collect{|o| [User::LOGIN_NAMES[o], o]}
  end
  def status_options all=false
    options=[User::STATUS_ACTIVE, User::STATUS_INACTIVE].collect{|o| [User::STATUS_NAMES[o], o]}
    options=[['Active & inactive',0]]+options if all
    options
  end
  def coordinator_options all=false
    options=[["Unassigned", 0]]+User.coordinators.collect{|u| [u.last_name_f,u.id]}
    options=[['All coordinators',-1]]+options if all
    options
  end
end
