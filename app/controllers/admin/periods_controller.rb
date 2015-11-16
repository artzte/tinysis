class Admin::PeriodsController < AdminBaseController

  before_filter :get_periods, :except => :update
  before_filter :set_meta

protected
  def set_meta
    super :tab1 => :settings, :tab2 => :periods, :title => 'Settings - Class Periods'
  end

  def get_periods
    @periods = Setting.periods
  end

public
  def show
    @periods = Setting.periods
  end

  def edit
    @periods = Setting.periods
  end

  def update
    periods = []
    unless params[:start]
      flash[:notice] = 'You must define at least one period slot.'
      edit
      render :action => edit
      return
    end

    params[:start].keys.each do |period|
      periods << ClassPeriod.new(params[:start][period], params[:end][period], period)
    end
    Setting.periods = periods.sort_by{|period| period.period}
    flash[:notice] = 'Thanks for updating the class periods.'
    redirect_to periods_path
  end

end
