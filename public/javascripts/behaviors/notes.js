$j(document).ready(function(){
  (function($){
    // Add a new note -- actually creates the note DB object
    $('ul.notes a.add_note').live('click', function() {
      var el = $(this);
      var ul = el.closest('ul');
      UI.show_progress();
      $.ajax({
        url: this.href,
        type: 'POST',
        data: "",
        complete: UI.hide_progress,
        success:function(html){
          var li = $(html);
          var textarea = li.find('textarea');
          
          ul.find('li:first').after(li);
          
          textarea.trigger('tiny_notes_setup');
        },
        error:Util.error
      });
      return false;
    });
    
    // Open an editor for the note
    $('ul.notes a.edit').live('click', function() {
      var el = $(this);
      UI.show_progress();

      $.ajax({
        url: this.href,
        data: "",
        complete: UI.hide_progress,
        success:function(html){
          var li, editor;
          
          // get containing LI, we are replacing it with editor LI
          li = el.closest('li');
          
          editor = $(html);

          li.replaceWith(editor);

          editor.find('textarea').trigger('tiny_notes_setup');
        },
        error:UI.error
      });
      return false;
    });
    
    $('ul.notes li').live('tiny_notes_delete', function(event) {
      var li = $(this);
      var tx = li.find('textarea');
      
      if(event.confirm && !confirm('Are you sure you want to delete this note?')) {
        return;
      }

      tx.trigger('tiny_notes_stop_observing');
      
      $j.ajax({
        url: event.href,
        type: 'POST'
      });
      
      li.fadeOut('fast', function(){li.remove();});
    });
    
    // Kill a note
    $('ul.notes a.delete').live('click', function() {
      var el = $(this);
      $(this).trigger({type: 'tiny_notes_delete', confirm: el.is('.cancel')===false, href: this.href});
      return false;
    });
    
    // Update a note and close editing / either by saving or reverting
    $('ul.notes a.update').live('click', function(event) {
      
      var el = $(this);
      var li = el.closest('li');
      var revert = el.is('.revert');
      var value = revert ? li.find('input.revert').val() : li.find('textarea').val();
      var tx = li.find('textarea');
      
      if((revert === false) && !Util.validate_nonblank(value)) {
        if(confirm('This blank note will be deleted when you close it. Do you want to delete the blank note?')) {
          li.trigger({type: 'tiny_notes_delete', confirm: false, href: li.find('a.delete').attr('href')});
        }
        return false;
      }

      tx.trigger('tiny_notes_stop_observing');

      $j.ajax({
        url: this.href,
        data: {note: value},
        type: 'POST',
        success: function(html) {
          var newLi = $(html);
          li.replaceWith(newLi);
          newLi.effect('highlight', 'fast');
        }
      });
      
      return false;
    });

    $('ul.notes textarea').live('tiny_notes_stop_observing', function() {
      var el = $(this);
      var timer = el.data('timer');
      if(timer) {
        clearInterval(timer);
        el.data('timer', null);
      }
    });
    
    $('ul.notes textarea').live('tiny_notes_save', function() {
      var el, url, value;
      
      el = $(this);
      
      value = this.value;
      
      if(value===this.cache)
        return;
        
      el.trigger('tiny_notes_cache');
      
      url = el.closest('li').find('a.autosave').attr('href');

      $.ajax({
        url: url,
        data: el.serialize(),
        type: 'POST'
      });
      
      $(this).trigger('tiny_notes_size');
    });
    
    $('ul.notes textarea').live('tiny_notes_setup', function() {
      var textarea = $(this);
      var timer = setInterval(function() {
          textarea.trigger('tiny_notes_save');
        }, 2000);
        
      textarea.trigger('tiny_notes_size');
      textarea.trigger('tiny_notes_cache');
    
      // save the timer so we can cancel it when the note box is closed
      textarea.data('timer', timer);
    
      // focus
      setTimeout(function() {
        textarea.focusInput(true);
      }, 10);
    });
    
    $('ul.notes textarea').live('tiny_notes_cache', function() {
      this.cache = this.value;
    });

    $('ul.notes textarea').live('tiny_notes_size', function() {
      var height;
      var el = $(this);
      
      // adjust height if necessary
      if(this.scrollHeight > this.clientHeight && this.clientHeight <= 250) {
        height = Math.ceil(this.scrollHeight/50)*50;

        // max 250 px in height
        if(height>250)
          height=250;
          
        // only expand
        if(this.clientHeight<height) {
          el.css('height', ''+height+'px');
        }
      }
    });
    
    $('ul.notes li.edit textarea').livequery('blur', function() {
      $(this).trigger('tiny_notes_save');
    });
    
    
    // This popup code activates on the student report form
    $('a.notes').live('click', function() {
      var a = $(this);
      var popup = a.next();
      popup.trigger({type: 'tiny_notes_popup', anchor: a});
      return false;
    });
    
    $('ul.notes.popup').live('tiny_notes_popup', function(event) {
        var popup = $(this);
        var a = event.anchor;
        var offset;
        
        $('ul.notes.popup').hide();

        popup.show();
        
        offset = popup.offset();

        if(offset.left+popup.outerWidth() > 900) {
          popup.css('left', 900-popup.outerWidth() + 'px');
        }
    });
    
    $('ul.notes.popup').live('click', function() {
      $(this).hide();
      return false;
    });

  })($j);
});

