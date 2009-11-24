var Status = {
  reg_id : /status_(\d+)/,
  update : function(event) {
    var form = event.findElement('tr');
    var match = Status.reg_id.exec(form.id);
    var status_id = match[1];
    
    params = Form.serialize(form);
    if($('status_fte_hours') && (!Util.validate_number($F('status_fte_hours')) || parseInt($F('status_fte_hours')) >25)) {
      alert('Please enter a number from 0 to 25 for the FTE hours.');
      $('status_fte_hours').focus();
      return;
    }
    new Ajax.Request('/status/update_status/'+status_id,{parameters:params})
  },
  bind : function() {
    // if this ID is availabel there is some kind of status form to bind to
    if($('status_academic')==null)
      return;
      
    $('status_academic').observe('change', Status.update);

    if($('status_fte_hours'))
      $('status_fte_hours').observe('blur', Status.update);
    if($('status_held_periodic_checkins'))
      $('status_held_periodic_checkins').observe('change', Status.update);
    if($('status_attendance'))
      $('status_attendance').observe('change', Status.update);
    if($('status_met_fte_requirements'))
      $('status_met_fte_requirements').observe('change', Status.update);
  }
};


// Functions for adding credits to the contract or to an enrollment
var Credit = {
  container_id : function(credit_id, parent_class, parent_id) {
    switch(parent_class){
    case 'User':
      return 'ca_user_'+credit_id;
    case 'Enrollment':
      return 'ca_enrollment_'+parent_id;
    case 'Contract':
      return 'ca_contract_'+parent_id;
    case 'GraduationPlan':
      return 'ca_graduationplan_'+parent_id;
    }
  },
  show_add : function(elem_type, elem_id) {
    Modalbox.show('/credit/editor/'+elem_type+'/'+elem_id,{title:'Add credit'}); 
    return false;      
  },
  credit_editor : function(credit_id) {
    Modalbox.show('/credit/editor/'+credit_id,{title:'Update credit'})
  },
  worksheet_editor : function(credit_id) {
    Modalbox.show('/credit/editor/'+credit_id,{title:'Update credit'})
  },
  combine_editor : function(event) {
    event.stop();
    var url = event.findElement('a').href;
    selected = Credit.selected_credits();
    if(selected.length < 2) {
      alert("Please select at least two credits to combine.")
      return;
    }
    Modalbox.show(url+'?c='+selected.join(','),{title:'Combine credits'});
  },
  validate : function() {
    credits = $('credits');
    if(credits && Util.validate_float(credits.value)==false) {
      alert('Please enter a numeric/decimal credits value in the format n.dd.');
      credits.select();
      return false;
    }
    override = $('credits_override');
    if(override && Util.validate_nonblank(override.value) && !Util.validate_float(override.value)) {
      alert('Please enter a numeric/decimal credit override value in the format n.dd, or leave the field blank if you don\'t wish to override.');
      override.select();
      return false;
    }
    if($F('course') == null) {
      alert('Please select a course for this credit.');
      return false;
    }
    return true;
  },
  add : function(parent_class, parent_id) {
    if(!Credit.validate())
      return false;
    params = Form.serialize("credit_form");
    Modalbox.hide();
    UI.show_progress();
    url = '/credit/add/'+parent_class+'/'+parent_id;
    new Ajax.Request(url, {postBody:params,onSuccess:Util.success,onFailure:Util.error});
    return false;
  },
  save : function(credit_id, parent_class, parent_id) {
    if(!Credit.validate())
      return false;
    params = Form.serialize("credit_form");
    update_id = Credit.container_id(credit_id, parent_class, parent_id);
    Modalbox.hide();
    UI.show_progress();
    new Ajax.Updater(update_id, '/credit/update/'+credit_id, {postBody:params,onSuccess:Util.success,onFailure:Util.error});
    return false;
  },
  destroy : function(credit_id, parent_class, parent_id) {
    update_id = Credit.container_id(credit_id, parent_class, parent_id);
    if(confirm("Are you sure you want to delete this credit and any associated notes?"))
      new Ajax.Updater(update_id, '/credit/destroy/'+credit_id,{onSuccess:Util.success,onFailure:Util.error})
  },
  admin_destroy : function(event) {
    var selected = Credit.selected_credits();
    event.stop();
    
    if(selected.length < 1) {
      alert('Please select at least one credit to delete.');
      return;
    }
    if(!confirm("Are you sure? Be sure to notify the class instructor!")) {
      return false;
    }
    
    var form = new Template("<form action='#{action}?c=#{credits}' method='post'></form>");
    event.findElement('div').insert({top:form.evaluate({action:event.findElement('a').href,credits:selected.join(',')})});
    form = event.findElement('div').down('form');
    form.submit();
  },
  approve : function(credit_id) {
    course_id = $('course_id_'+credit_id).value
    if(course_id == "0") {
      alert('You can\'t approve a credit that has a generic course assigned to it. Please update the course assignment by clicking on the course link.');
      $('approve_'+credit_id).checked = false;
      return;
    }
    credits = $('course_credits_'+credit_id).value
    val = $('approve_'+credit_id).checked ? 1 : 0;
    if(credits == "0" && val == 1 && !confirm("Are you sure you want to approve zero credits for this?")) {
      $('approve_'+credit_id).checked = false;
      return;
    }
    UI.show_progress();
    new Ajax.Request('/credit/approve/'+credit_id, {asynchronous:true, evalScripts:true, onComplete:function(t){UI.hide_progress()}, parameters:'v=' + val})
  },
  selected_credits : function() {
    selected = new Array();
    inputs = $$('.select_credit');
    for(i = 0; i < inputs.length; i++) {
      if(inputs[i].checked == true) {
        match = /^ca_(\d+)$/.exec(inputs[i].id);
         id = match[1];
        selected.push(id);
      }
    }
    return selected;
  },
  combine : function(student_id) {
    if(!Credit.validate()) {
      return false;
    }
    return true;
  },
  split : function(credit_id) {
    UI.show_progress();
    new Ajax.Updater('worksheet','/credit/split/'+credit_id, {onSuccess:Util.success,onFailure:Util.error})
  }
};

var Attendance = {
  meeting_id : 0,
  pick_roll : function(contract_id) {
    Modalbox.show('/attendance/pick_roll/'+contract_id,{title:"Take attendance",width:400}); 
    return false;    
  },
  page_calendar : function(year, month, page, contract_id, meeting_id) {
    month += page;
    if(month==13) {
      month = 1;
      year++;
    }
    if(month == 0) {
      month = 12;
      year--;
    }
    url = '/attendance/show_calendar/'+contract_id+'/'+year+'/'+month;
    if(meeting_id) {
      url += '/'+meeting_id
    }
    new Ajax.Updater('att_calendar', url, {method:'get'});
  },
  update : function(participant_id, participation) {
    for(i = 0; i < 4; i++) {
      $('p_'+participant_id+'_'+i).className = (participation == i ? 'sel' : '');
    }
    new Ajax.Request('/attendance/update/'+participant_id+'/'+participation,{onFailure:Attendance.update_failed});
    return true;
  },
  update_all : function(meeting_id) {
    participation = $('update_all').value;
    Element.show('progress')
    new Ajax.Updater('worksheet','/attendance/update_all/'+meeting_id+'/'+participation,{onFailure:Attendance.update_failed,onSuccess:Attendance.update_all_success});
    return true;
  },
  update_failed : function(t) {
    Element.hide('progress');
    alert(t.responseText);
  },
  update_all_success : function() {
    Element.hide('progress');
    UI.fade_notice('Attendance updated.');
  }
};

var ContractCategory = {
  show_add : function() {
    Modalbox.show('/admin/categories/new',{title:"Add contract category",width:500,method:'get'}); 
    return false;    
  },
  show_edit : function(id) {
    Modalbox.show('/admin/categories/'+id,{title:"Edit contract category",width:500,method:'get'})
  },
  edit : function(id) {
    if(!Util.validate_nonblank($F('category_name'))) {
      alert('Please fill in name for the category.');
      return false;
    }
    return true;
  },
  destroy : function(event) {
    event.stop();
    if(!confirm("Are you sure you want to delete this category?"))
      return false;
      
    Util.post_through_form(event.findElement('div'), event.element().href);
  },
  assign_to_group: function(item,group) {
    gr = /^gr_(\d+)$/.exec(group.id);
    if(gr==null) {
      return false;
    }
    cat = /^cat_(\d+)$/.exec(item.id);
    if(cat==null) {
      return false;
    }
    new Ajax.Request('/admin/categories/'+cat[1]+'/'+gr[1],{onSuccess:ContractCategory.update_success});
    return true;
  },
  update_success: function(t) {
    Util.success();
    $('container').innerHTML = t.responseText;
    ContractCategory.setup_draggables();
  },
  add_catalog_group: function() {
    if($('gr_new')) {
      return false;
    }
    new Insertion.Top('contract_categories',"<li id=\"gr_0\"><div id=\"handle_0\" class=\"div_handle\">&nbsp;</div><div class=\"gr_inner\">&nbsp;</div></li>");
    Droppables.add("gr_0",{onDrop:ContractCategory.assign_to_group,scroll:window});
    Sortable.create('contract_categories',{onUpdate:ContractCategory.arrange_groups,scroll:window});
    return true;
  },
  arrange_groups: function() {
    new Ajax.Request('/admin/categories/sort',{asynchronous:true,parameters:Sortable.serialize("contract_categories"),onSuccess:ContractCategory.update_success});
  },
  setup_draggables: function() {
    Sortable.create('contract_categories',{tag:'li',onUpdate:ContractCategory.arrange_groups,scroll:window});

    var groups = $('contract_categories').select('li.group');
    var glen = groups.length;
    var group, g;
    var clen, c, category, categories;
    
    for(g = 0; g < glen; g++) {
      group = groups[g];
      Droppables.add(group,{onDrop:ContractCategory.assign_to_group,scroll:window});
      categories = group.select('div.category');
      for(c = 0, clen = categories.length; c < clen; c++) {
        category = categories[c];
        new Draggable(category,{constraint:'vertical',handle:'p_handle'});
      }
    }
  }
};


var Util = {
  reg_float : /^\d+(\.\d{0,2})?$/,
  validate_float : function(str) {
    return Util.reg_float.test(str);
  },
  validate_nonblank : function(str) {
    return !str.strip().blank();
  },
  reg_numeric : /^\d+$/,
  validate_number : function(str) {
    return Util.reg_numeric.test(str.strip());
  },
  reg_date : /^\s*\d{4}\/\d{2}\/\d{2}$/,
  validate_date : function(str) {
    return Util.reg_date.test(str);
  },
  success : function(t) {
    UI.hide_progress();
    UI.fade_notice('Update successful.');
    if(Modalbox.MBwindow)
      Modalbox.hide();
  },
  error : function(t) {
    UI.hide_progress();
    if(t==null||t.responseText==null||t.responseText.blank())
      alert('Update failed.');
    else
      alert("Update failed:\n\n"+t.responseText);
  },
  focus_first: function(input_type) {
    if(input_type==null)
      input_type = 'input[type="text"]';
    var input = $('content').down(input_type);
    if(input) {
      input.focus();
      input.select();
    }
  },
  focus_error: function() {
    var div = $('content').down('.fieldWithErrors');
    var input;
    if(div) {
      input = div.down('input');
      if(input==null)
        input = div.down('textarea');
      if(input) {
        input.focus();
        input.select();
        return;
      }
    }
    return Util.focus_first();
  },
  // send a POST to the specified URL by depositing a on-fly FORM object
  // in the CONTAINER and then submitting it
  post_through_form: function(container, url) {
    var form = new Template("<form action='#{action}' method='post'></form>");
    container.insert({top:form.evaluate({action:url})});
    Util.form_post.bind(container).defer();
  },
  form_post: function() {
    this.down('form').submit();
  },
  stripe_counter : 0,
  stripe: function(tbody) {
    Util.stripe_counter = 0;
    tbody.select('tr').each(function(el) {
      el.removeClassName('alt0');
      el.removeClassName('alt1');

      el.addClassName('alt'+Util.stripe_counter);

      Util.stripe_counter++;
      Util.stripe_counter%=2;
    });
  }
};

var Period = {
  reg: new RegExp(/^\s*(\w+):\s*([012]?\d):(\d{2})\s*-\s*([012]?\d):(\d{2})\s*$/),
  msg: new Template("Line #{line}: #{error}"),
  parse: function(text) {
    var a = text.split('\n');
    var len = a.length;
    var periods = [];
    var match;
    var errors = [];
    var good = false;
    for(var i = 0; i < len; i++) {
      if(a[i].strip().blank())
        continue;
      if(match = Period.reg.exec(a[i])) {
        h1 = parseInt(match[2]);
        m1 = parseInt(match[3]);
        h2 = parseInt(match[4]);
        m2 = parseInt(match[5]);
        
        if(h1>23||h2>23||m1>59||m2>59) {
          errors.push(Period.msg.evaluate({line:i+1,error:"Invalid time specified?"}));
        }
        else if(h1>h2||h1==h2&&m1>m2) {
          errors.push(Period.msg.evaluate({line:i+1,error:"Period starts later than it ends? Use 24-hour time values?"}));
        }
        else {
          periods.push({period: match[1], start: match[2]+":"+match[3], end: match[4]+":"+match[5]});
        }
      }
      else {
        errors.push(Period.msg.evaluate({line:i+1,error:"Invalid format."}));
      }
    }
    if(errors.length>0) {
      alert(errors.join('\n'));
      return null;
    }
    else
      return periods;
  },
  period_fields: new Template("<input type='hidden' name='start[#{period}]' value='#{start}'/><input type='hidden' name='end[#{period}]' value='#{end}'/>"),
  submit:function(event) {
    var periods = Period.parse($F('periods'));
    if(periods==null) {
      event.stop();
      return;
    }
    
    var form = event.element();
    form.select('input[type="hidden"]').each(function(el){el.remove()});
    
    var len = periods.length;
    for(var i = 0; i < len; i++) {
      form.insert(Period.period_fields.evaluate({period:periods[i].period,start:periods[i].start,end:periods[i].end}));
    }
  }
};


var Textile = {
  example : function(container) {
    var div = container.parentNode.select("div").first();
    div.toggle(); 
    return false;
  }
};

var UI = {
  show_progress : function() {
    Element.show('progress');
  },
  hide_progress : function() {
    Element.hide('progress');
  },
  fade_notice : function(notice) {
    $("flash_msg").innerHTML = notice;
    $("flash").show();
    UI.clear_notice();
  },
  clear_notice : function() {
    new Effect.Fade('flash', {delay:3, duration:3});
  }
};



