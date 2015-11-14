module SearchHelper
protected  
  # returns an url-ized version of the search parameters for caching
  # in various places
  def qstring(fp)
    find = ""
    fp.each{|k,v| find << "#{k}=#{v}&" }
    find.chomp '&'  
  end
  
  def setup_detail_variables(collection)
    @index = params[:i].to_i
    @count = collection.length
  end
  
  def setup_page_variables(collection, per_page)
  
    @count = collection.length
    
    if collection.empty?
      @page = 0
      @page_items = []
      @page_range = [0,0]
      @page_count = 0
      return
    end
    
    if params[:i]
      @page = (params[:i].to_i / per_page) + 1
    else
      @page ||= (params[:pg] ? params[:pg].to_i : 1)
    end
    
    @page_count = (@count / per_page) + (@count % per_page > 0 ? 1 : 0)
    @page = 1 if @page == 0 || @page > @page_count
    
    page_start = per_page * (@page-1)
    page_end = @count >= @page*per_page ? (@page*per_page)-1 : @count-1
    @page_items = collection[page_start..page_end]
    @page_range = [page_start+1, page_end+1]
    
    @fp ||= {}

  end
  
  def store_session_pager(section)
    
    session[section] = @fp
    
  end
  
  def get_session_pager(section)
    
    @fp = session[section] || {}
    
  end
  
  def init_fp(params, symbols)
    
    @fp = {}
    symbols.each do |s|
      @fp[s] = @params[s]
    end
    @fp
    
  end

public

  #######################################################################
  # Detail and Results Listing Items
  
  # returns a div containing the search parameters in a hidden
  # tag, used by various ajax functions
  def find_params
    content_tag 'div', hidden_field_tag('find', qstring(@fp)), :id => 'find_params'
  end

  #######################################################################
  # Detail Items
  
  def link_to_prev_item(link, collection, action, options = {})
  
    if @index <= 1
      content_tag 'span', link
    else
      fp = @fp.merge({:i => @index-1})
      link_to link, { :action => action, :id => collection[@index-2]}.update(fp), options
    end
  
  end
  
  def link_to_next_item(link, collection, action, options = {})

    if @index >= @count
      content_tag 'span', link
    else
      fp = @fp.merge({:i => @index+1})
      link_to link, { :action => action, :id => collection[@index] }.update(fp), options
    end

  end


  def link_to_results(link, results_action = nil)
    link_to link, { :action => results_action, :i => @index }.update(@fp)
  end
  
  def fp_with_index
    hash = @fp.dup
    hash[:i] = @index
    hash
  end

  #######################################################################
  # Results Items
  
  # gets the pages array for the list
  def pages_array()
  
    (1..@page_count).to_a

  end
  
  # renders a select tag of pages, along with an observe field to
  # update the search listing with the indicated page
  def select_pages
    
    a = pages_array()
    [
      select_tag('pg', options_for_select(a, @page), :disabled => @page_count == 0)
    ].to_s
    
  end
  
  # returns a previous pages link
  def link_to_prev_page(link)
  
    if @page <= 1
      content_tag 'span', link, :class => 'smaller'
    else
      fp = @fp.merge({:pg => @page-1})
      link_to "<span>#{link}</span>", { :action => controller.action_name }.update(fp), :class=>'btn smaller'
    end
  
  end
  
  # returns a next pages link
  def link_to_next_page(link)
  
    if @page >= @page_count
      content_tag 'span', link, :class => 'smaller'
    else
      fp = @fp.merge({:pg => @page+1})
      link_to "<span>#{link}</span>", { :action => controller.action_name }.update(fp), :class=>'btn smaller'
    end
  end
  
  # link to an edit page
  def link_to_detail_action(link, action, collection, item)
     link_to link, { :action => action, :id => item, :i => collection.index(item)+1}.update(@fp)  
  end
  
  # link to an add page
  def link_to_add(link, action)
     link_to link, { :action => action}.update(@fp)  
  end
  
  
    
end
