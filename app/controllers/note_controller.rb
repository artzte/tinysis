class NoteController < ApplicationController

	# there are some handy ID-formatting functions in the helper that
	# are also needed here.
	before_filter :login_required
	before_filter :get_note_and_check_privileges, :except => :create

protected
	def get_note_and_check_privileges
		@note = Note.find(params[:id])

		privs = @note.privileges(@user)
    render :text => "You don't have privileges to do this.", :status => 500 and return unless privs[:edit_note]
	  
	end
public
	def edit
		render :partial => "note/note_edit",  :object => @note
	end

  def create
		parent_element = eval(params[:notable_class]).find(params[:notable_id].to_i)
		
		privs = parent_element.privileges(@user)
    render :text => "You don't have privileges to do this.", :status => 500 and return unless privs[:create_note]
		
		@note = parent_element.notes.create(:author => @user)
		
		@new = true
		
		render :partial => "note/note_edit",  :object => @note
  end

	def destroy
  	@note.destroy
  	
  	render :nothing => true
	end
	
	def update
	  if params[:note] && params[:note].blank?
	    @note.destroy
	    render :nothing => true
	    return
	  end 
	  
		@note.note = params['note']
		@note.author = @user
		@note.save!
		
		render :partial => "note/note_item",  :object => @note, :locals => {:editable => true}
	end

	def save
	  
	  # this is wacky - but sometimes autosave gets triggered and the javascript sends up a blank note after save was pressed
	  render :nothing => true and return if params['note'].blank?
	  
		@note.note = params['note']
		@note.author = @user
		@note.save!
		
		render :nothing => true
	end

	def revert
		@note.update_attribute(:note, params[:note])
		
		render :partial => "note/note_item",  :object => @note, :locals => {:editable => true}
	end
end
