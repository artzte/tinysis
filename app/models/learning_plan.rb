class LearningPlan < ActiveRecord::Base

  include StripTagsValidator

  belongs_to :user
  has_and_belongs_to_many :learning_plan_goals, :join_table => 'learning_plans_to_goals', :order => 'required DESC, position'
  has_many :notes, :as => :notable
  validates_presence_of :year, :user

  # Return a hash describing privileges of the specified user
  # on this learning plan

  def privileges(u)

    # create a new privileges object with no rights
    p = TinyPrivileges.new

    # user must be specified otherwise no privileges
    return p if u.nil?

    # an admin has full privileges
    return p.grant_all if u.admin?

    ##########################################
    # see if the user is the student's coordinator - if there is
    # no coordinator we are done, there are no privileges

    return p.grant_all if u == user.coordinator

    ##########################################
    # USER IS THE STUDENT, OR ANY STAFF MEMBER
    # grant read and note privileges.

    if u == user or u.privilege >= User::PRIVILEGE_STAFF

      p[:view] =
      p[:browse] =
      p[:create_note] =
      p[:view_note] = true

    end

    return p
  end

end
