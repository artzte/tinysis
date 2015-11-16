class Admin::CreditBatchesController < AdminBaseController

  before_filter :set_meta
  helper :note

protected
  def set_meta title = nil
    super :tab1 => :admin, :tab2 => :credit_batches, :title => title || 'Credit Batches'
  end

public

  def index

    @approved = CreditTransmittalBatch.credits_approved_for_transmittal

    @batches = CreditTransmittalBatch.batches_with_counts

    setup_page_variables @batches, 20

  end

  def show

    @batch = CreditTransmittalBatch.find(params[:id])
    @credit_assignments = @batch.credit_assignments
    @credit_notes = Note.notes_hash(@credit_assignments)

    get_associated_students

    set_meta "Credit Batch #{@batch.id}"
  end

  # Create a credits transmittal batch
  def create

    @batch = CreditTransmittalBatch.create_batch(@user)

    unless @batch
      flash[:notice] = "There were no credits to finalize at this time."
      redirect_to :action => 'index'
      return
    end

    @credit_assignments = @batch.credit_assignments

    count = @credit_assignments.length

    get_associated_students

    flash[:notice] = "Finalized #{count} credits."

    redirect_to credit_batch_path(@batch)
  end

protected
  def get_associated_students
    user_ids = @credit_assignments.collect{|c| c.user_id}.uniq.join(',')

    case params[:o]
    when nil
      order = 'last_name, first_name'
    when 'gd'
      order = 'district_grade DESC, last_name, first_name'
    when 'ga'
      order = 'district_grade ASC, last_name, first_name'
    end
    @order = params[:o] || 'n'

    @students = User.find(:all, :conditions => "id in (#{user_ids})", :order => order)
    @credit_assignments_count = @credit_assignments.length
    @credit_assignments = @credit_assignments.group_by(&:user_id)
  end

end
