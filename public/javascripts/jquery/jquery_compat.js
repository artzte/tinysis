$j = jQuery.noConflict();

jQuery.fn.found = function() {
  return (this.length>0);
};

// wrap focus() in a protected block
jQuery.fn.focusInput = function(select_all) {
  var el = this.get(0);
  try {
    if(el) {
      el.focus();
      if(select_all) {
        el.select();
      }
    }
  }catch(e){console.log(e);};
  return this;
};


if (typeof String.trim !== 'function') {
  String.prototype.trim = function() {
    return this.gsub(/^\s+|\s+$/, '');
  };
}

if (typeof String.blank !== 'function') {
  String.prototype.blank = function() {
    return ($j.trim(this)==='');
  };
}

if (typeof String.present !== 'function') {
  String.prototype.present = function() {
    return ($j.trim(this)!=='');
  };
}

if (typeof String.evaluate !== 'function') {
  String.prototype.evaluate = String.prototype.evaluate || function(params_hash) {
    var result = this;
    for(sub in params_hash) {
      if(params_hash.hasOwnProperty(sub)) {
        result = result.replace(new RegExp("#{"+sub+"}",'g'), params_hash[sub]);
      }
    }
    return result;
  };
}

