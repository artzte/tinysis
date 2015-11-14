module ContractsSearchHelper
  
protected

  def contracts_index
    
    contracts_find
    setup_page_variables @contracts, 20
    @fp = {:c=>@closed, :t=>@term, :f=>@facilitator, :g=>@category, :pg=>@page}
    store_session_pager('contract')
    
  end
  
  def contracts_index_init
    
    get_session_pager('contract')

    @facilitator_options = [['All staff', -1]]+User.staff_users.collect{|u| [u.last_name_f, u.id]} 
    @category_options = [['All categories', -1]]+Category.find(:all, :order => 'name').collect{|c| [c.name, c.id]}
    
    @terms = Term.all
    
    current_year = coor_term.school_year
    previous_terms = @terms.find_all{|t| t.school_year < current_year}
    @current_terms = @terms - previous_terms
    previous_years = previous_terms.collect{|t| t.school_year}.uniq.sort{|x,y|y<=>x}
    
    @term_options = [["All #{current_year} terms", -1]]+previous_years.collect{|y|["All #{y} terms",y*-1]}+@current_terms.collect{|t| [t.name, t.id]}
    
    params[:c] ||= @fp[:c]
    params[:t] ||= @fp[:t]
    params[:f] ||= @fp[:f]
    params[:g] ||= @fp[:g]
    
    @closed = 1 if params[:c] == "1"
    @term = params[:t] ? params[:t].to_i : -1
    @facilitator = params[:f] ? params[:f].to_i : @user.id
    @category = params[:g] ? params[:g].to_i : -1
    
    get_session_pager('contract')

    # if any of the filter variables have changed from the stored session, reset pager to 1
    if {:c =>@closed, :t=>@term, :f=>@facilitator, :g=>@category} != {:c =>@fp[:c], :t=>@fp[:t], :f=>@fp[:f], :g=>@fp[:g]}
      @page = 1
    end
    
  end

  def contracts_find
  
    @contracts = []
    
    @conditions = []
    @parameters = []
    
    init_contract_filters if self.respond_to? :init_contract_filters
      
    contracts_index_init
    
    unless @closed
      @conditions << "(contract_status != ?)"
      @parameters << Contract::STATUS_CLOSED
    end
    
    # term choices = -1 are all current year terms
    # negative value means a different year's terms
    # positive value means a specific term 
    if @term == -1
      terms_join = "INNER JOIN terms ON terms.id = contracts.term_id AND terms.school_year = #{coor_term.school_year}"
    elsif @term < 0
      terms_join = "INNER JOIN terms ON terms.id = contracts.term_id AND terms.school_year = #{@term * -1}"
    else
      terms_join = "INNER JOIN terms ON terms.id = contracts.term_id AND terms.id = #{@term}"
    end
    
    unless @facilitator == -1
      @conditions << "(facilitator_id = ?)"
      @parameters << @facilitator
    end
    
    unless @category == -1
      @conditions << "(category_id = ?)"
      @parameters << @category
    end
    
    if @conditions.empty?
      cond = nil
    else
      cond = [@conditions.join(' and ')]+@parameters
    end
    
    q = []
    q << "SELECT contracts.*, terms.name AS term_name, terms.credit_date as term_credit_date, CONCAT(users.last_name, ', ', LEFT(users.first_name, 1)) AS facilitator_name, categories.name AS category_name, COALESCE(enrollments_count.count,0) AS active_enrollments FROM contracts"
    q << "LEFT JOIN (SELECT COUNT(enrollments.id) as count, contract_id FROM enrollments WHERE enrollments.enrollment_status = #{Enrollment::STATUS_ENROLLED} GROUP BY enrollments.contract_id) AS enrollments_count ON enrollments_count.contract_id = contracts.id"
    q << terms_join
    q << "INNER JOIN categories ON categories.id = contracts.category_id"
    q << "INNER JOIN users ON users.id = contracts.facilitator_id"
    
    unless @conditions.empty?
      q << "WHERE"
      q << @conditions.join(' and ')
    end
    
    q << "ORDER BY term_credit_date, contracts.name"
    
    @contracts = Contract.find_by_sql([q.join(' ')]+@parameters)
    
  end

end