module StripTagsValidator
  class RailsSanitize
    include ActionView::Helpers::SanitizeHelper
  end

  ##########################################################################
  # Strip tags from all text fields before validating

  def before_validation
    self.class.columns.each do |c|
      if self[c.name] and [:string, :text].include?(c.class)
        self[c.name] = RailsSanitize.full_sanitizer.sanitize(self[c.name])
      end
    end
  end

end
