$j.fn.stripe_table = function() {
  $(this).each(function() {
    var table = $j(this);

    table.find('tbody tr').removeClass('alt1');
    table.find('tbody tr').removeClass('alt0');
    table.find('tbody tr:visible:odd').addClass('alt1');
    table.find('tbody tr:visible:even').addClass('alt0');
  });
};

$j(document).ready(function() {
  $j('.behavior.year_filter select').change(function() {
    document.location = $j(this).closest('form').attr('action')+"/"+this.value;
  });
  
  $j('table.striped').stripe_table();
});