class Admin::EnrollmentsController < AdminBaseController

  before_filter :set_meta
  
protected
  def set_meta
    super :tab1 => :admin, :tab2 => :enrollments, :title => "Admin - Finalize Enrollments"
  end

public  
  def index
    @terms = Term.enrollments_report
  end
  
  def edit

    @term = Term.find(params[:id]) rescue
    unless @term
      flash[:notice] = 'No term specified.'
      redirect_to :action => 'dt'
      return
    end

    @contracts = Contract.find(:all, :conditions => "term_id = #{@term.id}", :include => [:facilitator, :term], :order => 'users.last_name, users.first_name, contracts.name')

    @open_start = Contract.count_by_sql("select count(*) from contracts where (term_id = #{@term.id}) and contract_status <> #{Contract::STATUS_CLOSED}")
    @closed_start = @contracts.length - @open_start

    enrollments = Enrollment.find(:all, :conditions => "contract_id in (#{@contracts.collect{|c| c.id}.join(',')})", :select => 'contract_id, finalized_on')
    @enrollments = {}
    @contracts.each{|c| @enrollments[c.id] = {:total => 0, :active => 0}}
    enrollments.each do |e|
      @enrollments[e.contract_id][:total] += 1
      unless e.finalized_on?
        @enrollments[e.contract_id][:active] += 1
      end
    end
    @contracts = @contracts.group_by{|c| c.contract_status == Contract::STATUS_CLOSED ? 0 : 1}
    @contracts[0] ||= []
    @contracts[1] ||= []
  end
  
  def update

    @term = Term.find(params[:id])

    @contracts = Contract.find(:all, :conditions => "term_id = #{@term.id}", :include => [:facilitator, :term], :order => 'users.last_name, users.first_name, contracts.name')
    finalize_date = Time.now
    finalized = 0
    closed = 0
    @contracts.each do |contract|
      contract.enrollments.each do |e|
        if e.set_finalized(@user, finalize_date)
          finalized += 1
        end
      end

      if contract.enrollments.find(:first, :conditions => "enrollment_status < #{Enrollment::STATUS_CLOSED}")
        contract.update_attribute(:contract_status, Contract::STATUS_ACTIVE)
      elsif contract.contract_status != Contract::STATUS_CLOSED
        closed += 1
        contract.update_attribute(:contract_status, Contract::STATUS_CLOSED)
      end
    end

    flash[:notice] = "Finalized #{help.pluralize(finalized, 'enrollment')}; closed #{help.pluralize(closed, 'contract')}."
    redirect_to finalize_enrollments_show_path(@term)
  end

  # Show a report summarizing what's closed and what's not
  def show

    @term = Term.find(params[:id]) if params[:id]
    
    redirect_to admin_enrollments_index_path and return unless @term

    @open = @term.contracts_active.find(:all, :include => :facilitator, :order => 'users.last_name, users.first_name, contracts.name')
    if(@open.length>0)
      @open_enrollments = Enrollment.find(:all, :conditions => "contract_id in (#{@open.collect{|c| c.id}.join(',')}) and enrollment_status < #{Enrollment::STATUS_CLOSED}", :include => [:participant, {:contract => :facilitator}], :order => 'users.last_name, users.first_name')
      @enrollment_count = @open_enrollments.length
      @open_enrollments = @open_enrollments.group_by{|e| e.contract}
    end
    @closed = @term.contracts_closed(:all, :include => :facilitator, :order => 'facilitator.last_name, facilitator.first_name, contracts.name')

  end



end
