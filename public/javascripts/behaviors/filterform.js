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
// 
// var FilterForm = Class.create();
// 
// FilterForm.prototype = {
//   form_id : '',
//   
//   initialize : function(form_id) {
//     this.form_id = form_id;
//     
//     var form, elements, i, el, text = null;
//     
//     form = $(this.form_id);
//     
//     elements = form.getElements();
//     
//     form.observe('submit', this.form_submitted.bindAsEventListener(this));
//     
//     for(i = 0; el = elements[i]; i++) {
//       switch(el.tagName.toLowerCase()) {
//       case 'select':
//         el.observe('change', this.form_changed.bindAsEventListener(this));
//         break;
//       case 'input':
//         switch(el.type.toLowerCase()) {
//         case 'radio':
//         case 'checkbox':
//           el.observe('change', this.form_changed.bindAsEventListener(this));
//           break;
//         case 'text':
//           if(!text)
//             text = el;
//           break;
//         }
//         break;
//       }
//     }
//     if(text)
//       Field.focus(text);
//   },
//   
//   form_submitted : function() {
//     return true;
//   },
//   
//   form_changed : function() {
//     $(this.form_id).submit();
//   }
// };
