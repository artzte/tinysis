$j(document).ready(function() {
  $j('.behavior.year_filter select').change(function() {
    document.location = $j(this).closest('form').attr('action')+"/"+this.value;
  });
});