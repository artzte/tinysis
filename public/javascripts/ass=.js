


var Gradesheet = Class.create({
  initialize: function(tb_assignments, tb_students, tb_grades, td_class) {
    try{
  },
  

  // Remove the event obersvers
  unobserve : function() {
    var tbody = this.tb_grades.find('tbody').get(0);
    tbody.stopObserving('click', tbody.at_click);
    document.stopObserving('keydown', document.at_focus);
    
    var externals = $j('input,select,textarea');
    var len = externals.length;
    var el;
    for(var i = 0; i < len; i++) {
      el = externals[i];
      if(el.at_focus) {
        el.stopObserving('focus', el.at_focus);
        el.at_focus = null;
      }
    }
  },
  
  cel_for: function(assignment, enrollment) {
    var col = this.assignments.indexOf(assignment);
    var row = this.enrollments.indexOf(enrollment);
    if(row==-1||col==-1)
      alert('whoops');
    return this.cel_at(row,col);
  },
  close_note: function() {
    var mb = $j('#MB_content');
    var notes = mb.find('li.note').length;
    var current = mb.find('a.current');
    
    var parseFormAction = new RegExp(/\/contracts\/(\d+)\/assignments\/(\d+)\/record\/(\d+)\?value=(.)/);
    
    // grab the url from the first updater link
    var match = parseFormAction.exec(current.get(0));
    var assignment = match[2];
    var enrollment = match[3];
    
    var el = this.cel_for(assignment, enrollment);
    
    el.trigger('tinysis:assignments:nav_to');
    
    var input = $j(el).find('input');
    input.val(match[4].toUpperCase());
    if(input.val()=='M')
      input.val('');
    el.at_val = input.val();
    
    if(notes>0)
      el.addClass('note');
    else
      el.removeClass('note');
  }
});

var Turnin = {
  bind_status : function() {
    $$('a.status').invoke('observe', 'click', Turnin.update);
  },
  update_from_modal : function(el) {
    el = $j(el);
    el.closest('ul').find('a.current').removeClass('current');
    el.addClass('current');
    new Ajax.Request(el.attr('href'));
    return false;
  },
  show_status_form : function(a) {
    $(a).nextSiblings().first().toggle();
    return false;
  },
  update : function(event) {
    event.stop();
    UI.show_progress();
    new Ajax.Request(event.element().href,{onFailure:Util.error,onComplete:UI.hide_progress});
    event.element().up('ul.status_updater').select('a').invoke('removeClassName', 'current');
    event.element().addClassName('current');
    
    event.element().up('.status_updater').hide();
    var form_link = event.element().up('td.status').down('a');
    form_link.update(event.element().innerHTML);
    form_link.highlight();
  }
}

