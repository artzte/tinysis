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
    
    
    // BUGBUG note even sure if this is still supported in the markup
    // popup notes on student form
    $('a.notes').live('click', function() {
      $(this).trigger('tiny_notes_popup');
      return false;
    });
    
    $('ul.notes.popup').live('click', function() {
      $(this).hide();
      return false;
    });

  })($j);
});


// var Note = {
//   
//   // Get the note ID given a container
//   parse_container_id : new RegExp(/^notes_(\w+)_(\d+)$/),
//   note_id_for : function(li) {
//     if(li.tagName.toLowerCase()!='li')
//       li = li.up('li');
//       
//     var reg = new RegExp(/^note_(\d+)$/);
//     var match = reg.exec(li.id);
//     
//     return match[1];
//   },
// 
//   // Set up event handlers on the form
//   bind_form : function(li) {
//     var tx = li.select('textarea').first();
//     
//     tx.observe('blur', function(event){Note.autosave(event.element());});
//     tx.timedObserver = new Form.Element.Observer(tx, 4, Note.autosave);
//     this.size_box(tx);
//     Field.focus(tx);
//   },
// 
//   // Add a new note
//   add : function(link){
//     link = $(link);
//     
//     var li = link.up('li');
//     var ul = link.up('ul');
//     var match = this.parse_container_id.exec(li.id);
//     UI.show_progress();
//     new Ajax.Request('/note/new/'+match[1]+'/'+match[2],{
//       onFailure:Util.error,
//       onSuccess:function(t){Note.show_add(ul, t);}
//     });
//     return false;
//   },
//   show_add : function(ul, t) {
//     ul.select('li').first().insert({after:t.responseText});
//     UI.hide_progress();
//     
//     var li = ul.select('li.edit').first();
//     
//     Note.bind_form(li);
//   },
//   
//   // Edit a note
//   edit : function(link) {
//     link = $(link);
// 
//     var li = link.up('li');
//     
//     UI.show_progress();
//     new Ajax.Request('/note/edit/'+this.note_id_for(li),{
//       onFailure:Util.error,
//       onSuccess:function(t){Note.show_edit(li, t);}
//     });
//   },
//   show_edit : function(li, t) {
//     var old = li;
//     old.replace(t.responseText);
//     li = $(old.id);
//     
//     Note.bind_form(li);
// 
//     UI.hide_progress();
//   },
//   
//   // These get called on a periodic timer
//   autosave : function(el) {
//     Note.size_box(el);
//     new Ajax.Request('/note/autosave/'+Note.note_id_for(el),{parameters:Note.encoded(el)});
//   },
//   
//   // An encoded parameter string for the textarea value
//   encoded : function(tx) {
//     var obj = {note:tx.getValue()};
//     return Object.toQueryString(obj);    
//   },
//   
//   // Autosize the note box
//   size_box : function(tx) {
//     var height;
// 
//     if(tx.scrollHeight > tx.clientHeight && tx.clientHeight <= 250) {
//       height = Math.ceil(tx.scrollHeight/50)*50;
//       
//       if(height>250)
//         height=250;
//       tx.style.height = ''+height+'px';
//     }
//   },
//   
//   // Kill a note
//   destroy : function(link, msg) {
//     link = $(link);
//     
//     var li = link.up('li');
// 
//     if(msg && !confirm(msg))
//       return false;
// 
//     Note.cancel_observer(li);
//     
//     new Ajax.Request('/note/destroy/'+this.note_id_for(link),{
//       onFailure:Util.error
//     });
//     
//     li.remove();
//   },
//   
//   // Revert back to the old value.
//   revert : function(link) {
//     link = $(link);
//     var li = link.up('li');
//     UI.show_progress();
//     
//     Note.cancel_observer(li);
//     
//     new Ajax.Request('/note/revert/'+this.note_id_for(li), {
//       parameters:'revert='+li.select('input[type=hidden]').first().getValue(),
//       onSuccess:function(t){Note.close(li, t).bind(this);},
//       onFailure:Util.error
//     });
//   },
//   
//   // Cancel the timed observer on the textbox
//   cancel_observer : function(li) {
//     var tx = li.down('textarea');
//     if(tx && tx.timedObserver) {
//       tx.timedObserver.stop();
//       tx.timedObserver = null;
//     }  
//   },
//   
//   // Save and close
//   save : function(link) {
//     link = $(link);
//     var li = link.up('li');
//     var tx = li.select('textarea').first();
//     var value = tx.getValue();
//     var erase = false;
//     
//     if(!Util.validate_nonblank(value)) {
//       if(confirm('This blank note will be deleted when you close it. Do you want to delete the blank note?'))
//         erase = true;
//       else
//         return false;
//     }
// 
//     var success;
// 
//     Note.cancel_observer(li);
// 
//     if(erase)
//       success = function(t){
//           this.remove();
//         }.bind(li);
//     else
//       success = function(t){
//         Note.close(li, t).bind(this);
//       };
//     
//     UI.show_progress();
//     new Ajax.Request('/note/update/'+this.note_id_for(li),{
//       parameters:Note.encoded(tx),
//       onFailure:Util.error,
//       onComplete:UI.hide_progress,
//       onSuccess:success
//     });
//   },
//   
//   // Replace the form with the response text
//   close : function(li,t) {
//     li.replace(t.responseText);
//     UI.hide_progress();
//   },
//   
//   // Popup a note relative to its link
//   pop : function(event) {
//     var a = event.element();
//     var div = event.element().next();
//     
//     div.toggle();
// 
//     if(div.offsetWidth+a.cumulativeOffset().left > 900) {
//       div.setStyle({left: 900-div.offsetWidth + 'px'});
//     }
//     event.stop();
//   }
// };
// 
// 
// 
// 
// 
