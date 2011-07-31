if(navigator.appName=="Microsoft Internet Explorer") {
  console = {
    log: function(msg){
      $j("<p>").html(msg).appendTo('#debug');
    }
  };
}

var FilterForm = Class.create();

FilterForm.prototype = {
  form_id : '',
  
  initialize : function(form_id) {
    this.form_id = form_id;
    
    var form, elements, i, el, text = null;
    
    form = $(this.form_id);
    
    elements = form.getElements();
    
    form.observe('submit', this.form_submitted.bindAsEventListener(this));
    
    for(i = 0; el = elements[i]; i++) {
      switch(el.tagName.toLowerCase()) {
      case 'select':
        el.observe('change', this.form_changed.bindAsEventListener(this));
        break;
      case 'input':
        switch(el.type.toLowerCase()) {
        case 'radio':
        case 'checkbox':
          el.observe('change', this.form_changed.bindAsEventListener(this));
          break;
        case 'text':
          if(!text)
            text = el;
          break;
        }
        break;
      }
    }
    if(text)
      Field.focus(text);
  },
  
  form_submitted : function() {
    return true;
  },
  
  form_changed : function() {
    $(this.form_id).submit();
  }
};

// Inline editing
var InlineEditor = Class.create({
  default_options : $H({ajax_update:true}),
  initialize: function(container, options) {
    this.edit_container = container;
    this.edit_container.editor = this;
    if(options)
      options = this.default_options.update(options);
    else
      options = this.default_options;
    this.post_ajax = options.get('ajax_update');
  },
	bind_edit : function(a) {
	  if(a.tagName.toLowerCase()!='a')
	    a = a.select('a.edit').first();
	  a.observe('click', this.edit.bindAsEventListener(this) );
	},
	edit : function(event) {
	  event.stop();
	  UI.show_progress();
	  new Ajax.Request(event.findElement('a').href, {method:'get', onComplete:this.edit_complete.bindAsEventListener(this)});
	},
	edit_complete : function(t) {
	  this.edit_container.update(t.responseText);
    this.bind_form.bind(this).defer();
	},
	bind_form : function() {
	  if(this.post_ajax==true) {
	    var form = this.edit_container.select('form').first();
	    form.observe('submit',this.update.bindAsEventListener(this));
	    
	    var cancel_link = form.select('a').first();
	    cancel_link.observe('click', this.cancel.bindAsEventListener(this));
    }
	  UI.hide_progress();
	},
	update : function(event) {
	  event.stop();
	  
	  if(this.validate && !this.validate(event.element()))
	    return;
	    
	  UI.show_progress();
	  
	  new Ajax.Request(event.element().action, {
	    parameters:event.element().serialize(),
	    onComplete:UI.hide_progress,
	    onFailure:this.edit_complete.bind(this),
	    onSuccess:this.show.bind(this)
	    });
	},
	show : function(t) {
	  this.edit_container.update(t.responseText);
	  this.bind_edit.bind(this).defer(this.edit_container);
	  if(this.post_show)
	    this.post_show.bind(this).defer();
	    
	  UI.hide_progress();
	},
	cancel : function(event) {
	  event.stop();
	  UI.show_progress();
	  var a = event.findElement('a');
	  new Ajax.Request(a.href, {
	    method:'get',
	    onComplete:UI.hide_progress,
	    onSuccess:this.show.bind(this)
	    });
	}
});

// Utility functions for assignment reports
var Assignment = {
  show_all : function() {
    var details = $$('.details');
    details.invoke('show');
    return false;
  },
  show : function(a) {
    a.nextSiblings().first().toggle();
  }
};



// Functions for editing terms
var Term = {
  destroy : function(event) {
    event.stop();
    if(!confirm("Are you sure you want to delete this term?"))
      return false;
      
    Util.post_through_form(event.findElement('td'), event.element().href);
  }
};

// Functions for editing terms
var AdminEalr = {
  destroy : function(event) {
    event.stop();
    if(!confirm("Are you sure you want to delete this ealr?"))
      return false;
      
    Util.post_through_form(event.findElement('td'), event.element().href);
  }
};

var GraduationWorksheetEditor = new Class.create(InlineEditor, {
  validate : function(form) {
    return GraduationWorksheet.validate(form);
  },
  post_show : function() {
    this.edit_container.down('a.delete').observe('click', GraduationWorksheet.destroy);
    GraduationWorksheet.recalc_totals.defer(this.edit_container.up('.req'));
  }
});

// Functions for the graduation worksheet
var GraduationWorksheet = {
  init : function() {
    var i, els;
    
    GraduationWorksheet.make_draggables();
    
    for(i = 0, els = $$('.req.credit.child'); els[i]; i++) {
      GraduationWorksheet.set_droppable(els[i],{onDrop:GraduationWorksheet.drop});
    }
    
    for(i = 0, els = $$('.req.credit.parent'); els[i]; i++) {
      GraduationWorksheet.set_droppable(els[i],{onDrop:GraduationWorksheet.drop});
    }
    
    GraduationWorksheet.bind_unassigns($('a_index'));
    
    for(i = 0, els = $$('a.new'); els[i]; i++) {
      els[i].observe('click', GraduationWorksheet.add);
    }
    
    if($('general'))
      for(i = 0, els = $('general').select('.mapping'); els[i]; i++) {
        GraduationWorksheet.editor_for(els[i]);
      }

    if($('service'))
      for(i = 0, els = $('service').select('.mapping'); els[i]; i++) {
        GraduationWorksheet.editor_for(els[i]);
      }

    for(i = 0, els = $$('a.delete'); els[i]; i++) {
      els[i].observe('click', GraduationWorksheet.destroy);
    }
    
    window.setInterval(GraduationWorksheet.position_unassigned, 200);
  },
  position_unassigned : function() {
    var pos = $('credit').viewportOffset();
    if(pos[1] < 10)
      $('unassigned').addClassName('pinned');
    else
      $('unassigned').removeClassName('pinned');
  },
  destroy : function(event) {
    event.stop();
    var container = event.findElement('.mapping');

    if(!confirm("Are you sure you want to remove the entry \"" + container.down('.name').innerHTML.strip()+ "\""))
      return false;
    new Ajax.Request(event.element().href);

    new Effect.Highlight(container);
    
    Element.remove.delay(1, container.id);
    
    var req_parent = event.findElement('.req');

    GraduationWorksheet.recalc_totals.delay(2,req_parent);
  },
  validate : function(form) {
    var errors = [];
    var el = form.down('#mapping_name');
    if(el && !Util.validate_nonblank(el.value)) {
      errors.push(el.up('p').down('label').innerHTML.strip()+' cannot be blank.');
    }
    el = form.down('#mapping_quantity');
    if(el && !Util.validate_number(el.value)) {
      errors.push(el.up('p').down('label').innerHTML.strip()+' must be number of hours.');
    }
    if(errors.length>0) {
      alert("Please review your entries and address the following:\n\n" + errors.join('\n'));
      return false;
    }
    return true;
  },
  add : function(event) {
    event.stop();
    UI.show_progress();
    new Ajax.Request(event.element().href,{method:'get',onComplete:GraduationWorksheet.add_done.bind(event.findElement('.req').down('.mappings'))});
  },
  add_done : function(t) {
    var el = this.down('.mapping.new');
    if(el)
      el.replace(t.responseText);
    else
      this.insert({top:t.responseText});
    GraduationWorksheet.bind_add.defer(this);
    UI.hide_progress();
  },
  bind_add : function(el) {
    el.down('form').observe('submit', GraduationWorksheet.submit_mapping);
    el.down('a.cancel').observe('click', function(event){event.findElement('.mapping.new').remove(); event.stop();});
  },
  submit_mapping : function(event) {
    event.stop();

    if(!GraduationWorksheet.validate(event.element()))
      return false;
      
    UI.show_progress();

    new Ajax.Request(event.element().action, {parameters:event.element().serialize(),onSuccess:GraduationWorksheet.create_done.bind(event.element().up('.mappings'))});
  },
  create_done : function(t) {
    this.down('.mapping.new').replace(t.responseJSON[1]);
    
    GraduationWorksheet.editor_for_new.defer(t.responseJSON[0]);
    GraduationWorksheet.recalc_totals.defer(this.up('.req'));
    UI.hide_progress();
  },
  editor_for_new : function(mapping_id) {
    GraduationWorksheet.editor_for($('cm_'+mapping_id));
  },
  editor_for : function(el) {
    var editor = new GraduationWorksheetEditor(el);
    editor.bind_edit(el.down('a.edit'));
    el.down('a.delete').observe('click', GraduationWorksheet.destroy);
  },
  student_id : function() {
    return parseInt($('student').value);
  },
  reg_req_id : new RegExp(/req_(\d+)/),
  requirement_id : function(el) {
    var matches = GraduationWorksheet.reg_req_id.exec(el.id);
    return parseInt(matches[1]);
  },
  reg_ca_id : new RegExp(/ca_(\d+)/),
  credit_assignment_id : function(el) {
    var matches = GraduationWorksheet.reg_ca_id.exec(el.id);
    return parseInt(matches[1]);
  },
  set_draggable : function(el) {
    new Draggable(el,{revert:true});
  },
  make_draggables : function() {
    $('unassigned').select('.unassigned').each(function(el){GraduationWorksheet.set_draggable(el);});
  },
  set_droppable: function(el) {
    Droppables.add(el,{hoverclass:'hover',onDrop:GraduationWorksheet.drop});
  },
  drop : function(draggable, droppable, event) {
    draggable.remove();
    droppable.down('.mappings').insert({bottom:"<div class='mapping progress'>"+draggable.innerHTML+"</div>"});
    
    var url = new Template("/students/#{id}/graduation/assign/#{gr}/#{ca}");
    new Ajax.Request(
      url.evaluate({
        id:GraduationWorksheet.student_id(), 
        gr:GraduationWorksheet.requirement_id(droppable), 
        ca:GraduationWorksheet.credit_assignment_id(draggable)}), 
      {
        onComplete:Util.hide_progress,
        onSuccess:GraduationWorksheet.update_mappings.bind(droppable)
      });
  },
  update_mappings : function(t) {
    this.down('.mappings').innerHTML = t.responseText;
    GraduationWorksheet.recalc_totals.defer(this);
    GraduationWorksheet.bind_unassigns.defer(this);
  },
  recalc_totals : function(el) {
    var subtotal = el.down('.subtotal');
    if(!subtotal)
      return;
    var hours = el.select('.hours').collect(function(a){return a.innerHTML.strip();});
    var total = GraduationWorksheet.sum(hours);
    subtotal.update(total);
    new Effect.Highlight(el.down('.subtotal'));
    var parent = el.up('.req');
    if(parent)
      GraduationWorksheet.recalc_totals(parent);
  },
  sum : function(a) {
    var total = 0;
    var len = a.length;
    for(var i = 0; i < len; i++)
      total += parseFloat(a[i]);
    return total.toPrecision(2);
  },
  bind_unassigns : function(el) {
    el.select('a.unassign').invoke('observe', 'click', GraduationWorksheet.unassign);
  },
  unassign : function(event) {
    event.stop();
    
    var container = event.element().up('.req');
    
    var el = event.findElement('.mapping');
    event.element().remove();
    el.remove();
    el.addClassName('progress');
    $('credit_assignments').insert({bottom:el});
    UI.show_progress();
    new Ajax.Request(event.element().href,{onComplete:GraduationWorksheet.unassign_complete});
    
    GraduationWorksheet.recalc_totals.defer(container);
  },
  unassign_complete : function(t) {
    UI.hide_progress();
    $('credit_assignments').update(t.responseText);
    GraduationWorksheet.make_draggables();
  }
};


// Functions for editing graduation requirements
var AdminGraduationRequirement = {
  destroy : function(event) {
    new Ajax.Request(event.element().href);
    event.element().remove();
  },
  make_sortable : function() {
    AdminGraduationRequirement.make_sortable_ul('credit');
    AdminGraduationRequirement.make_sortable_ul('general');
    AdminGraduationRequirement.make_sortable_ul('service');
  },
  make_sortable_ul : function(el) {
    if($(el)===null)
      return;
    Sortable.create(el, {
      handle:'handle',
      onUpdate: AdminGraduationRequirement.sort
    });
  },
  sort : function(container) {
    UI.show_progress(); 
    new Ajax.Request('/admin/plans/sort', {
      asynchronous:true, 
      parameters:Sortable.serialize(container),
      onComplete:function(){
        Util.success();
      }
    });
  }
};

// Functions for editing credits
var AdminCredit = {
  destroy : function(event) {
    var el = jQuery(this);
    
    event.preventDefault();
    
    if( !confirm("Are you sure you want to delete " + el.closest('tr').find('td:first').text() + "?") )
      return false;
      
    Util.post_through_form(el.closest('td').get(0), this.href);
  }
};

// Functions for editing learning plan goals
var LearningPlanGoal = {
  destroy : function(event) {
    event.stop();
    if(!confirm("Are you sure you want to delete this learning plan goal?"))
      return false;
      
    Util.post_through_form(event.findElement('td'), event.element().href);
  },
  make_sortable : function() {
    Sortable.create("goals", {
      tag:'tr',
      handle:'handle',
      onUpdate:function(tbody) {
        UI.show_progress(); 
        new Ajax.Request('/admin/learning_plans/sort', {
            asynchronous:true, 
            evalScripts:true,
            parameters:Sortable.serialize("goals"),
            onComplete:function(response){
              Util.success();
              Util.stripe(this);
            }.bind(tbody)
          });
        }
      }
    );
  },
  success : function(t) {
    Util.success();
    LearningPlanGoal.make_sortable();    
  }
};



var Account = {
  observe_inactive : function() {
    var el = $('account_status');
    $('account_date_inactive').disabled = (el.getValue()=="1");
    $('account_status').observe('click', Account.toggle_inactive_date);
  },
  toggle_inactive_date: function(event) {
    $('account_date_inactive').disabled = (event.element().getValue=='1');
  }
};



// Functions for adding participants to a contract.
var Enrollment = {
  add : function(contract_id) {
    Modalbox.show('/contracts/'+contract_id+'/enrollments/new',{title:'Add Participants'}); 
    return false;    
  },
  validate_add : function() {
    if(Form.serialize("students_to_enroll") === "") {
      alert('Please select some participants to enroll.');
      return false;
    }
    return true;
  },
  drop : function(event) {
    event.stop();
    var student = event.element().up('td').down('h3').innerHTML.strip();
    if(!confirm('Are you sure you want to drop '+ student+'? All status reports, assignment feedback, etc. will also be deleted.'))
      return;
    Util.post_through_form(event.findElement('td'), event.element().href);
  },
  update : function(event) {
    event.stop();
    
    UI.show_progress();

    new Ajax.Request(event.element().href, {
        onComplete:UI.hide_progress,
        onSuccess:Enrollment.update_success.bind(event.findElement('div.status'))});
  },
  bind_links : function(container) {
    container.select('a.approve','a.cancel_enrollment','a.fulfill','a.role').invoke('observe', 'click', Enrollment.update);
    container.select('a.drop').invoke('observe', 'click', Enrollment.drop);
    container.select('a.show').invoke('observe', 'click', Enrollment.show_updator);
    container.select('a.hide').invoke('observe', 'click', Enrollment.close_updator);
  },
  update_success : function(t) {
    this.innerHTML = t.responseText;
    Enrollment.bind_links(this);
    new Effect.Highlight(this);
  },
  show_updator : function(event) {
    var a = event.element();
    a.next('.status_updater').toggle();
    event.stop();
  },
  close_updator : function(event) {
    event.findElement('.status_updater').hide();
    event.stop();
  },
  reset_credits : function(event) {
    event.stop();
    
    if(!confirm('Are you sure you want to reset all active enrollments to the base? This will replace all credit assignments, including any notes, with the contract defaults.'))
      return;
      
    Util.post_through_form(event.findElement('div'), event.findElement('a').href);
  }
};
  

var actions_table = {
  c_school: {
    a_catalog: function() {new FilterForm('filter');}
  },
  c_contract: {
    a_index: function() {
      new FilterForm('filter');
      $$('a.destroy').invoke('observe', 'click', Contract.destroy);
    },
    a_show: function() { 
      $$('a.edit').each(function(a){ 
        var editor = new ContractEditor(a.up('div.editable'));
        editor.bind_edit(a);
      });
      $j('#timeslot_use_other').live('change', function() {
        $j('#othertime').toggle($j(this).is(':checked'));
      });
      
    }
  },
  c_enrollment: {
    a_index: function(){ 
      Enrollment.bind_links($('enrollments'));
      
      var el = $('defaults');
      el = el.down('a');
      if(!el)
        return;
        
      el.observe('click', function(event) {
          event.stop();
          new Ajax.Updater(event.element().up('#defaults'), event.findElement('a').href, {method:'get'});
        });
        
      el = $('reset_credits');
      el.observe('click', Enrollment.reset_credits);
    }
  },
  c_status : {
    a_contract: function() {new FilterForm('filter');},
    a_index: function() {new FilterForm('filter');},
    a_coor_report: function() {
      Status.bind();
    },
    a_contract_report: function() {
      Status.bind();
    }
  },
  c_students : {
    a_status: function() {
    }
  },
  c_graduation_plan : {
    a_index : function() {
      GraduationWorksheet.init();
    }
  },
  c_assignment : {
    a_index: function() {
      $j('.gradesheet').gradesheet();
    },
    a_new : function() {
      Util.focus_first();
    },
    a_edit : function() {
      Util.focus_first();
    },
    a_student : function() {
      $j('a.show_status_updater_form').click(function() {
        $(this).next().show();
        return false;
      });

      $j('.status_updater a').live('click', function() {
        var el = $j(this);
        var ul = el.closest('ul');
        var caller = ul.prev();

        ul.find('a').removeClass('current');
        el.addClass('current');
        $j.ajax({
          type: 'post',
          url: this.href
        });
        ul.hide();
        caller.html(el.html());
        return false;
      });
    }
  },
  c_attendance : {
    a_index: function() { new FilterForm('filter'); }
  },
  c_credit: {
    a_index: function() {
      if($('combine_link'))
        $('combine_link').observe('click', Credit.combine_editor);
      if($('admin_destroy_link'))
        $('admin_destroy_link').observe('click', Credit.admin_destroy);
    }
  },
  c_account: {
    a_edit : function() { Account.observe_inactive(); },
    a_update : function() { Account.observe_inactive(); },
    a_login: function() { Field.focus('user_login');},
    a_reset: function() { Field.focus('user_email');}
  },
  c_admin_accounts: {
    a_index: function() {new FilterForm('filter'); Field.focus('n');},
    a_edit : function() { Account.observe_inactive(); },
    a_update : function() { Account.observe_inactive(); },
    a_edit : function() { Account.observe_inactive(); },
    a_update : function() { Account.observe_inactive(); }
  },
  c_admin_terms: {
    a_index: function() { $$('a.destroy').invoke('observe', 'click', Term.destroy); },
    a_edit: Util.focus_first,
    a_create: Util.focus_error,
    a_update: Util.focus_error,
    a_new: Util.focus_first
  },
  c_admin_periods: {
    a_edit: function() { $('periods_form').observe('submit', Period.submit);},
    a_update: function() { $('periods_form').observe('submit', Period.submit);}
  },
  c_admin_credits: {
    a_index: function() { 
      jQuery('a.destroy').live('click', AdminCredit.destroy);
      jQuery('a.behavior.show_can_delete').click(function() {
        var table = $j("#credits_list");
        table.find('tbody tr').not('.can_delete').toggle();
        table.stripe_table();
        return false;
      });
    },
    a_edit: Util.focus_first,
    a_create: Util.focus_error,
    a_update: Util.focus_error,
    a_new: Util.focus_first
  },
  c_admin_credit_batches: {
    a_index: function(){
      $j('#create_credit_batch').submit(function(event) {
        return confirm("Are you sure you want to finalize credits at this time?");
      });
    }
  },
  c_admin_learning_plans: {
    a_index: function() { 
      $$('a.destroy').invoke('observe', 'click', LearningPlanGoal.destroy);
      LearningPlanGoal.make_sortable(); 
    },
    a_edit: function() {Util.focus_first('textarea');},
    a_create: Util.focus_error,
    a_update: Util.focus_error,
    a_new: function() {Util.focus_first('textarea');}
  },
  c_admin_categories: {
    a_index: function() {
      ContractCategory.setup_draggables;
      $$('a.destroy').invoke('observe', 'click', ContractCategory.destroy);
    }
  },
  c_admin_settings: {
    a_index: function() {
      var editor = new InlineEditor($('settings'),{ajax_update:false});
      editor.bind_edit($('settings').down('a'));
    }
  },
  c_admin_ealrs: {
    a_index: function() {
      new FilterForm('filter');
      $$('a.destroy').invoke('observe', 'click', AdminEalr.destroy);
    }
  },
  c_admin_plans: {
    a_index: function() {
      $$('a.destroy').invoke('observe', 'click', AdminGraduationRequirement.destroy);
      AdminGraduationRequirement.make_sortable();
    },
    a_new: Util.focus_first,
    a_edit: Util.focus_first,
    a_update: Util.focus_error,
    a_create: Util.focus_error
  }
};

$j(document).ready(function(){
  var controller = $j('div.app_c').attr('id');
  var action = $j('div.app_a').attr('id');

  if(actions_table[controller] && actions_table[controller][action]) {
    actions_table[controller][action].apply();
  }
    
  if($j('flash').is(":visible"))
    UI.clear_notice();
});

