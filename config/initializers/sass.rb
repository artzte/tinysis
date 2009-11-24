if defined? Sass::Plugin
  # allow nested style
  Sass::Plugin.options[:style] = :nested

  # only good syntax allowed 
  # :font-weight bold => BAD
  # font-weight: bold => GOOD 
  # Sass::Plugin.options[:attribute_syntax] = :alternate

  # all sass templates will live at public/sass (not public/stylesheets/sass)
  Sass::Plugin.options[:template_location] = "#{Rails.root}/public/sass"

  # all css files will be generated at public/stylesheets
  Sass::Plugin.options[:css_location] = "#{Rails.root}/public/stylesheets"
end