var Contract = {
	set_ealr : function(contract_id, ealr_id) {
		if($('ealr_'+ealr_id).checked) {
			val = 1;
		}
		else {
			val = 0;
		}
		new Ajax.Request('/contract/update_ealr/'+contract_id, {parameters:"e="+ealr_id+"&v="+val,onComplete:function(t){$('progress').hide();UI.fade_notice(t.responseText)}})		
	},
	show_copy : function(contract_id) {
		Modalbox.show('/contract/copy/'+contract_id,{title:'Copy contract',width:500,method:'get'});
		return false;
	},
	copy : function(contract_id) {
		params = Form.serialize('copy_contract');
		new Ajax.Request('/contract/copy/'+contract_id,{parameters:params,onSuccess:Contract.copy_success,onFailure:Contract.copy_failed});
		return false;
	},
	copy_success : function(t) {
		alert('The new contract has been created. You will now be redirected to the setup screen for your contract.');
		document.location = '/contracts/'+t.responseText;
		return false;
	},
	copy_failed : function(t) {
		alert(t.responseText);
		return false;
	},
	destroy : function(event) {
	  event.stop();
		if(confirm("Are you sure you want to delete this contract? Note that you will not be able to delete the contract unless you are the facilitator, or an administrator, and there are no other enrollments on this contract.") == false)
			return;
		Util.post_through_form(event.findElement('td'), event.element().href);
	},
	delete_success : function(t) {
		result = eval(t.responseText);
		row = $('c_'+result[0]);
		if(row) {
			tds = row.getElementsBySelector('td');
			tds[0].innerHTML = 'Deleted ' + result[1]
			len = tds.length;
			for(i = 1; i < len; i++) {
				tds[i].innerHTML = ''
			}
		}
		UI.hide_progress();
	}
};


var ContractEditor = Class.create(InlineEditor, {
  initialize: function($super, container) {
    $super(container);
  },
  post_show : function() {
    $$('h1').first().innerHTML = $F('contract_name');
    UI.fade_notice('Thank you for updating the contract.')
  }
})