(function($){
  $.fn.filter_form = function() {
    this.each(function(){
      var form = $(this);

      form.bind('submitted', function() {
        form.submit();
      });
      
      form.delegate('select', 'change', function() {
        form.trigger('submitted');
      });
      
      form.delegate('input[type=radio],input[type=checkbox]', 'change', function() {
        form.trigger('submitted');
      });
      
    });
  };
  
  $(document).ready(function() {
    $('.filter.resubmit form').filter_form();
  })
})(jQuery);
