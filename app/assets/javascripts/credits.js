// Functions for adding credits to the contract or to an enrollment
var Credit = {
  show_add : function(elem_type, elem_id, link_element) {
    var el = $j(link_element);
    var container = el.closest('ul.credits');
    Modalbox.show('/credit/editor/'+elem_type+'/'+elem_id,{title:'Add credit', container: container}); 
    return false;      
  },
  credit_editor : function(credit_id, link_element) {
    var el = $j(link_element);
    var container = el.closest('ul.credits');
    Modalbox.show('/credit/editor/'+credit_id,{title:'Update credit', container: container});
  },
  worksheet_editor : function(credit_id, link_element) {
    var el = $j(link_element);
    var container = el.closest('ul.credits');
    
    Modalbox.show('/credit/editor/'+credit_id,{title:'Update credit', container: container});
  },
  combine_editor : function(event) {
    event.stop();
    var url = event.findElement('a').href;
    selected = Credit.selected_credits();
    if(selected.length < 2) {
      alert("Please select at least two credits to combine.");
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
    if($F('course') === null) {
      alert('Please select a course for this credit.');
      return false;
    }
    return true;
  },
  add : function(parent_class, parent_id) {
    if(!Credit.validate()) {
      return false;
    }
    params = Form.serialize("credit_form");
    Modalbox.hide();
    UI.show_progress();
    url = '/credit/add/'+parent_class+'/'+parent_id;
    new Ajax.Request(url, {postBody:params, onSuccess: function(response) {

        Modalbox.options.container.replaceWith(response.responseText);
        Util.success(response);
        
      }, 
      onFailure:Util.error
    });
    return false;
  },
  save : function(credit_id, parent_class, parent_id) {
    if(!Credit.validate()) {
      return false;
    }
    params = Form.serialize("credit_form");
    Modalbox.hide();
    UI.show_progress();
    new Ajax.Request('/credit/update/'+credit_id, {postBody:params,
      onSuccess: function(response) {
        Modalbox.options.container.closest('tr').find('.approve input').attr('checked', false);
        Modalbox.options.container.replaceWith(response.responseText);
        Util.success(response);
      },
      onFailure:Util.error
    });
    return false;
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
    course_id = $('course_id_'+credit_id).value;
    if(course_id == "0") {
      alert('You can\'t approve a credit that has a generic course assigned to it. Please update the course assignment by clicking on the course link.');
      $('approve_'+credit_id).checked = false;
      return;
    }
    credits = $('course_credits_'+credit_id).value;
    val = $('approve_'+credit_id).checked ? 1 : 0;
    if(credits == "0" && val == 1 && !confirm("Are you sure you want to approve zero credits for this?")) {
      $('approve_'+credit_id).checked = false;
      return;
    }
    UI.show_progress();
    new Ajax.Request('/credit/approve/'+credit_id, {asynchronous:true, evalScripts:true, onComplete:function(t){UI.hide_progress();}, parameters:'v=' + val});
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
    new Ajax.Updater('worksheet','/credit/split/'+credit_id, {onSuccess:Util.success,onFailure:Util.error});
  }
};

$j('li.cr a.destroy').live('click', function(event) {
  var el = $j(this);

  event.preventDefault();
  new Ajax.Request(el.attr('href'),{onSuccess:Util.success,onFailure:Util.error});
  el.closest('li.cr').remove();
  return false;
});  
