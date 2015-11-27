(function($) {
  $.fn.gradesheet = function() {
    this.each(function(index) {
      var that = this;

      that.container = $(this);

      // Save the table elements
      that.tb_assignments = that.container.find('.at_ne table');
      that.tb_students = that.container.find('.at_sw table');
      that.tb_grades = that.container.find('.at_se table');

      that.legal_value = function(value) {
        return (value.length<=1)&&("CcIiEeLl ".indexOf(value)!=-1);
      };

      that.cel_at = function(row, col) {
        return $j($j(this.tb_grades.find('tbody tr')[row]).find('td')[col]);
      };

      that.cel_value = function(value) {
        if(value===null||value===undefined||value.toString().blank()||value==='m'||value==='M')
          return "&nbsp;";
        return value;
      };

      that.cel_enrollment = function(el) {
        return that.enrollments[el.at_row];
      };

      that.cel_assignment = function(el) {
        return that.assignments[el.at_col];
      };

      that.cel_student = function(el) {
        return $j(that.tb_students.find('tbody th')[el.at_row]).find('a').html();
      };

      that.cel_for = function(assignment, enrollment) {
        var col = this.assignments.indexOf(assignment);
        var row = this.enrollments.indexOf(enrollment);
        if(row==-1||col==-1)
          alert('whoops');
        return that.cel_at(row,col);
      };

      that.tb_grades.find('td.a').bind('tiny_gradesheet_send', function(event) {
        var url = "/contracts/#{contract}/assignments/#{assignment}/record/#{enrollment}".evaluate({
            contract: that.contract_id,
            assignment: that.cel_assignment(this),
            enrollment: that.cel_enrollment(this)
          });

        if(event.value==='')
          event.value='M';

        $.ajax({
          url: url,
          data: {value: event.value},
          type: 'POST'
        });
      });

      that.tb_grades.find('td.a').bind('tiny_gradesheet_note', function() {
        var td = $(this);
        var url = '/contracts/#{contract}/assignments/#{assignment}/feedback/#{enrollment}'.evaluate({
          contract:that.contract_id,
          assignment:that.cel_assignment(this),
          enrollment:that.cel_enrollment(this)});
        Modalbox.show(url, {
          title:'Feedback for '+that.cel_student(this),
          method:'post',
          beforeHide: function(){td.trigger('tiny_gradesheet_update_from_turnin_form');}
        });
      });

      $('#MB_content .status_updater a').live('click', function() {
        $(this).closest('ul').find('a').removeClass('current');
        $(this).addClass('current');
        $.ajax({
          type: 'post',
          url: this.href
        });
        return false;
      });

      that.tb_grades.find('td.a').bind('tiny_gradesheet_update_from_turnin_form', function() {
        var mb = $('#MB_content');
        var notes = mb.find('ul.notes li:not(.add)').length;

        $(this).trigger({
            type: 'tiny_gradesheet_update',
            value: mb.find('.status_updater a.current').attr('data-value'),
            notes: notes>0
          });
      });

      that.tb_grades.find('td.a').bind('tiny_gradesheet_update', function(event) {
        var el = $(this);

        if(event.notes)
          el.addClass('note');
        else
          el.removeClass('note');

        this.innerHTML = that.cel_value(event.value.toUpperCase());
      });

      that.tb_grades.find('td.a').bind('tiny_gradesheet_nav_to', function(event) {
        var td = $(this);
        if(event.input) {
          $(event.input).trigger({type: 'tiny_gradesheet_close_edit'});
        }
        else {
          that.container.trigger('tiny_gradesheet_close_edits');
        }
        that.container.trigger('tiny_gradesheet_close_focus');
        td.trigger('tiny_gradesheet_cel_focus');
        td.trigger('tiny_gradesheet_cel_edit');
      });

      // Cel gets focus
      that.tb_grades.find('td.a').bind('tiny_gradesheet_cel_focus', function() {
        var td = $(this);

        that.focus_td = td;
        td.addClass("focus");

        $(that.tb_students.find('tbody tr')[this.at_row]).addClass('select');

        return true;
      });

      // Cel becomes editable
      that.tb_grades.find('td.a').bind('tiny_gradesheet_cel_edit', function() {
        var el = $(this);
        var input = $('<input type="text" maxlength="1"/>').val( el.text().trim() );
        el.html(input);
        setTimeout(function() {
            try{
              input.get(0).focus();
            }catch(e){alert('ie');};
          }, 1);
      });

      // focused cel is not anymore
      that.container.bind('tiny_gradesheet_close_focus', function() {

        if(!that.focus_td)
          return;

        // Clear row and cel select
        that.tb_students.find('tbody tr').removeClass('select');
        that.focus_td.removeClass('focus');

        // Clear focus cel
        that.focus_td = null;
      });


      // clear edits on any open inputs in the grade table
      $('input,select,textarea').focus(function(event) {
        that.container.trigger('tiny_gradesheet_close_edits');
        that.container.trigger('tiny_gradesheet_close_focus');
      });

      // Handy key-codes table
      var Key = {
        KEY_BACKSPACE: 8,
        KEY_TAB:       9,
        KEY_RETURN:   13,
        KEY_ESC:      27,
        KEY_LEFT:     37,
        KEY_UP:       38,
        KEY_RIGHT:    39,
        KEY_DOWN:     40,
        KEY_DELETE:   46,
        KEY_HOME:     36,
        KEY_END:      35,
        KEY_PAGEUP:   33,
        KEY_PAGEDOWN: 34,
        KEY_INSERT:   45
      };

      // Keyboard handler
      that.keydown = function(event) {
        var row, col, input, ch, el, td;

        // Ignore anything coming from a modal
        if($('#MB_frame').found())
          return true;

        // Determine if event occurred within a table element, or if there
        // is an active editor
        el = $(event.target).closest('td.a');
        if(!el.found()) {
          el = that.focus_td;
        }
        if(!el)
          return true;

        td = el[0];

        row = td.at_row;
        col = td.at_col;
        input = el.find('input');

        switch(event.keyCode) {
        case Key.KEY_TAB:
          return;
        case Key.KEY_RETURN:
          if(input.found())
            input.trigger('tiny_gradesheet_close_edit');
          else if(that.focus_td)
            el.trigger('tiny_gradesheet_cel_edit');
          break;
        case Key.KEY_ESC:
          input.trigger({type: 'tiny_gradesheet_close_edit', cancel: true});
          return;
        case Key.KEY_HOME:
          if(el.at_col===0)
            return;
          that.cel_at(td.at_row,0).trigger({type: 'tiny_gradesheet_nav_to', input: input});
          break;
        case Key.KEY_END:
          if(td.at_col==that.col_count-1)
            return;
          that.cel_at(td.at_row,that.col_count-1).trigger({type: 'tiny_gradesheet_nav_to', input: input});
          break;
        case Key.KEY_LEFT:
          if(td.at_col===0)
            return;
          that.cel_at(td.at_row,td.at_col-1).trigger({type: 'tiny_gradesheet_nav_to', input: input});
          break;
        case Key.KEY_UP:
          if(td.at_row===0)
            return;
          that.cel_at(td.at_row-1,td.at_col).trigger({type: 'tiny_gradesheet_nav_to', input: input});
          break;
        case Key.KEY_RIGHT:
          if(td.at_col===that.col_count-1)
            return;
          that.cel_at(td.at_row,td.at_col+1).trigger({type: 'tiny_gradesheet_nav_to', input: input});
          break;
        case Key.KEY_DOWN:
          if(td.at_row===that.row_count-1)
            return;
          that.cel_at(td.at_row+1,td.at_col).trigger({type: 'tiny_gradesheet_nav_to', input: input});
          break;
        default:
          // ignore if readonly
          if(that.readonly)
            break;

          // Deal with keydown events coming into the input element
          if(input.found()) {
            ch = String.fromCharCode(event.keyCode).toUpperCase();

            // Note-time
            if(ch === 'N') {
              that.focus_td.trigger('tiny_gradesheet_note');
              return false;
            }
            // Legal character value
            else if(that.legal_value(ch)) {
              input.val(ch);
              el.trigger({type: 'tiny_gradesheet_send', value: ch});
              return false;
            }
            // Let anything through that's a control key combo
            else if(event.ctrlKey || event.altKey || event.metaKey) {
              return true;
            }
          }

          // Anything that's not into our input field let through
          else {
            return true;
          }
          break;
        }
        return false;
      };

      $(document).keydown(that.keydown);

      that.tb_grades.find('td.a').click(function(event) {
        var el = $(this);

        // set a timeout, if the timeout is still running when the next click comes in,
        // trigger the doubleclick action
        if(that.timer_dblclick) {
          event.type = "tiny_gradesheet_note";
          el.trigger(event);
        }
        else {
          that.timer_dblclick = setTimeout(function(){
              clearTimeout(that.timer_dblclick);
              that.timer_dblclick = null;
            }, 400);
        }
        if(el.find('input').found()) {
          return false;
        }
        el.trigger('tiny_gradesheet_nav_to');

        return false;
      });

      // Focus leaves an input cell, close the editor
      that.tb_grades.find('td.a input').live('blur', function() {
        $(this).trigger('tiny_gradesheet_close_edit');
      });

      // Close any active editor in the container
      that.container.bind('tiny_gradesheet_close_edits', function() {
        this.tb_grades.find('input').trigger('tiny_gradesheet_close_edit');
      });

      // Close the active editor
      that.tb_grades.find('td.a input').live('tiny_gradesheet_close_edit', function(event) {
        var el = $(this);
        var td = el.closest('td');
        var val = el.val();

        // explicit reset or value is not right, reset to cached value
        if(!that.legal_value(val)) {
          val = '';
        }

        val = that.cel_value(val);

        $(td).html(val);
      });

      // Bind the turnin form that cometh down from the cloud
      $('.turnin_form ul.status_updater a').click(function(){

        return false;
      });

      // Initialize the gradesheet.
      that.initialize = function() {

        UI.show_progress();

        // Make sure they're there
        if(!(that.container.found() && that.tb_assignments.found() && that.tb_students.found() && that.tb_grades.found())) {
          throw "Necessary container markup not found.";
        }

        // Read only table?
        that.readonly = that.container.is('.readonly');

        // contract db id
        that.contract_id = that.container.attr('data-contract-id');

        // focus table cel
        that.focus_td = null;

        // Init the table
        var rows = that.tb_grades.find('tbody tr');
        var cols;

        // Record and verify the column/row counts
        that.row_count = rows.length;
        that.col_count = that.tb_grades.find('tbody tr:first td').length;

        // Add row/column numbers to each TD for later reference
        rows.each(function(row) {
          $(this).find('td.a').each(function(col){
            this.at_row = row;
            this.at_col = col;
          });
        });

        // Initialize the enrollees and assignments lists
        that.assignments = $j.makeArray(that.tb_assignments.find('th').map(function() { return this.getAttribute('data-assignment-id');}));
        that.enrollments = $j.makeArray(that.tb_students.find('th').map(function() { return this.getAttribute('data-enrollment-id');}));

        // Adjust the sync'ed column sizes so they match the client area of the gradesheet
        that.tb_assignments.get(0).parentNode.style.width = that.tb_grades.get(0).parentNode.clientWidth.toString() + 'px';
        that.tb_students.get(0).parentNode.style.height = that.tb_grades.get(0).parentNode.clientHeight.toString() + 'px';

        var grades = that.tb_grades.parent();
        var names = that.tb_students.parent();

        grades.scroll(function() {
          names.scrollTop(grades.scrollTop());
        });

        UI.hide_progress();
      };

      try {
        that.initialize();
      }catch(e){console.log(e);}

      return that;
    });
  };
})(jQuery);
