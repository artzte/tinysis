(function($){
  $.fn.stripe_table = function() {
    $(this).each(function() {
      var table = $(this);

      table.find('tbody tr').removeClass('alt1');
      table.find('tbody tr').removeClass('alt0');
      table.find('tbody tr:visible:odd').addClass('alt1');
      table.find('tbody tr:visible:even').addClass('alt0');
    });
  };
  
  $('a.load-once').live('click', function() {
    var el = $(this);
    if(el.data('loaded')) {
      return false;
    }
    el.data('loaded', true);
    return true;
  });
  
  $(document).ready(function() {
    $('.behavior.year_filter select').change(function() {
      document.location = $(this).closest('form').attr('action')+"/"+this.value;
    });

    $('table.striped').stripe_table();
    
    var flash = $('#flash');
    if(flash.is(":visible")) {
      UI.fade_notice();
    }
    
  });  
})(jQuery);

