class AdminBaseController < ApplicationController

  before_filter :login_required, :admin_required

end
