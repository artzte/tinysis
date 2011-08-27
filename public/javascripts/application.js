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
    new Ajax.Request('/status/update_status/'+status_id,{parameters:params});
  },
  bind : function() {
    // if this ID is availabel there is some kind of status form to bind to
    if($('status_academic')===null)
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
    if(month === 0) {
      month = 12;
      year--;
    }
    url = '/attendance/show_calendar/'+contract_id+'/'+year+'/'+month;
    if(meeting_id) {
      url += '/'+meeting_id;
    }
    new Ajax.Updater('att_calendar', url, {method:'get'});
  }
};

jQuery('.behavior.submit-once').live('click submit', function(event) {
  var el = $(this);
  if(el.data('submitted')) {
    return false;
  }
  el.data('submitted', true);
});

jQuery('.behavior.attendance_update').live('click change', function(event) {
  var el = jQuery(this);
  var parent = el.closest('tr');
  var url;

  event.preventDefault();

  if(parent.data('processing')) {
    return;
  }

  // user clicked an already selected link
  if(el.is('a.sel')) {
    return;
  }

  parent.data('processing', true);

  if(el.is('a')) {
    parent.find('a.behavior.attendance_update').removeClass('sel');
    el.addClass('sel');
  }

  url = parent.find('a.behavior.attendance_update.sel').attr('href');

  console.warn(url);

  jQuery.post(url, {contact: parent.find('select.attendance_update').val()})
    .done(function() {
      parent.data('processing', false);
    });
});

var ContractCategory = {
  show_add : function() {
    Modalbox.show('/admin/categories/new',{title:"Add contract category",width:500,method:'get'}); 
    return false;    
  },
  show_edit : function(id) {
    Modalbox.show('/admin/categories/'+id,{title:"Edit contract category",width:500,method:'get'});
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
    if(gr===null) {
      return false;
    }
    cat = /^cat_(\d+)$/.exec(item.id);
    if(cat===null) {
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
    if(!t===null||t.responseText===null||t.responseText.blank())
      alert('Update failed.');
    else
      alert("Update failed:\n\n"+t.responseText);
  },
  focus_first: function(input_type) {
    if(input_type===null)
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
      if(input===null)
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
      match = Period.reg.exec(a[i]);
      if(match) {
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
    if(periods===null) {
      event.stop();
      return;
    }
    
    var form = event.element();
    form.select('input[type="hidden"]').each(function(el){el.remove();});
    
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
    var flash = $j('#flash');
    flash.html(notice);
    flash.show();
    UI.clear_notice();
  },
  clear_notice : function() {
    $j('#flash').fadeOut('slow');
  }
};



