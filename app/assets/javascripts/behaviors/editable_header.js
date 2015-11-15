(function($){

  $('.editable_head.behavior a.edit').live('click', function(event) {
    var el = $(this);
    var head = el.closest('.editable_head');
    event.preventDefault();
    head.data('editCache', head.html());
    head.html("<form action='"+el.attr('href')+"'><input type='text' value='" + head.data('textCache') + "'><input type='submit' value='submit' /></form>");
    _.defer(function(){
      try{
        head.find('input')[0].focus();
      }catch(e){}
    });
  });

  $('.editable_head.behavior form').live('submit', function(e) {
    var el = $(this);
    var val = el.find('input[type="text"]').val();
    var url = el.attr('action');
    var head = el.parent();

    e.preventDefault();
   
    head.html(head.data('editCache'));
    _.defer(function() {
      head.find('span').text(val);
    });

    $.ajax({
      url: url,
      type: 'post',
      data: {value: val}
    });
  });

})(jQuery);
