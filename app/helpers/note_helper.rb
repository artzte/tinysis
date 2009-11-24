module NoteHelper

  def notes_container(parent_element)
    "notes_#{parent_element.class}_#{parent_element.id}"
  end
  
	def note_container(note)
		"note_#{note.id}"	
	end
	
	def note_title(note)
		note_author = note.author ? note.author.name.downcase : 'Anonymous'
  	"#{note_author} - #{d(note.updated_at, true).downcase}"
	end
	
  # renders notes for an object with the following parameters
  #
  # object - the object to render notes for
  # :notes_hash - a hash table whose keys might contain the object - the
  # value will be the cached array of notes for that object
  # :editable = true (default) notes has linkable add and edit functions subject to
  # privileges
  def notes_for(object, options = {})
    
    options[:editable] = true if options[:editable].nil?
    
    render :partial => 'note/notes',  :object => object, :locals => {:options=>options}
    
  end
  
end
