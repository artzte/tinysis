module TinyForms

  class TinyForms < ActionView::Helpers::FormBuilder

    # options[:label] => Override the automatically generated label based on the attribute name
    # options[:required] => Adds a "required" class to the enclosing element if true
    # options[:tag] => Overrides the tagname of the enclosing element from "p"

    # Generic builder template for a field in which the label appears first
    BUILDER_FIELD = <<-END_SRC
      content = []
      ua = options[:ua] ? "<span class='ua'>\#{options[:ua]}</span>" : ''
      unless options[:label] == false || options[:label_position]==:after
        content << @template.content_tag("label", "\#{options[:label] || field.to_s.humanize}\#{ua}", :for => "\#{@object_name}_\#{field}")
      end
      content << super
      unless options[:label] == false || options[:label_position].nil?
        content << @template.content_tag("label", "\#{options[:label] || field.to_s.humanize}\#{ua}", :for => "\#{@object_name}_\#{field}")
      end
      content << error_message_on(field)
      content
    END_SRC


    # Label-after controls
    %w(check_box radio_button).each do |selector|
      src = <<-END_SRC
        def #{selector}(field, options = {})
          options[:label_position] = :after
          #{BUILDER_FIELD}
          @template.content_tag(options[:tag] || 'p', content.join('').html_safe, :class=>"#{selector}\#{options[:required]?' required':''}", :id => "p_\#{@object_name}_\#{field}")
        end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    # Label-before controls
    (field_helpers - %w(check_box radio_button) + %w{date_select}).each do |selector|
      src = <<-END_SRC
        def #{selector}(field, options = {})
          #{BUILDER_FIELD}
          @template.content_tag(options[:tag] || 'p', content.join('').html_safe, :class=>"#{selector}\#{options[:required]?' required':''}", :id => "p_\#{@object_name}_\#{field}")
        end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    def select(field, choices, options = {}, html_options = {})
      content = eval(BUILDER_FIELD)
      klass = "select"
      klass << " required" if options[:required]
      @template.content_tag(options[:tag] || 'p', content.html_safe, :class=>klass, :id => "p_#{@object_name}_#{field}")
    end
  end


  def tiny_form_for(record, options = {}, &proc)
    form_for(record,
             (options||{}).merge(:builder => TinyForms),
             &proc)
  end

  #####################################################################
  # Form helpers

  def label_for(theField, theLabel, theHelpstring = nil)
    "<label for=\"#{theField}\">#{theLabel}</label>"
  end


  def error_messages_for(object_name)
    object = instance_variable_get("@#{object_name}")
    error_messages_formatted object
  end

  def error_messages_formatted(object)
    if object && !object.errors.empty?
      content_tag("div",
        content_tag("h2",
          "Please fix the following:"
        ) +
        content_tag("ul", object.errors.full_messages.collect{|msg| content_tag("li", ">>&nbsp;#{msg}") },
                    "id" => "errorExplanation", "class" => "errorExplanation" )
      )
    else
      ""
    end
  end

  # override link to remote -- we always use the progress indicator.
  def tiny_link_to_remote(name, options = {}, html_options = {})

    options.update({ :complete => "Element.hide('progress')",
                     :before => "Element.show('progress')" })

    link_to_remote(name, options, html_options)
  end

  def tiny_observe_field(field_id, options = {})
    options.update({ :complete => "Element.hide('progress')",
                     :before => "Element.show('progress')" })

    observe_field(field_id, options)

  end

  def tiny_observe_form(field_id, options = {})
    options.update({ :complete => "Element.hide('progress')",
                     :before => "Element.show('progress')" })

    observe_form(field_id, options)
  end

  def tiny_sortable_element(field_id, options = {})
    options.update({ :complete => "Element.hide('progress')",
                     :before => "Element.show('progress')" })

    sortable_element(field_id, options)

  end

  def submit_button(caption, options = {})
    klass = 'btn'
    klass << '_small' if options[:small]
    "<input type='submit' value='#{caption}' class='#{klass}' />".html_safe
  end

  def cancel_button(url, options = {})
    url_button 'Cancel', url, options.merge({:class=>'cancel'})
  end

  def url_button(caption, url, options = {})
    klass = 'btn'
    klass << '_small' if options[:small]
    klass << ' ' << options[:class] if options[:class]
    id = ''
    id = " id='#{options[:id]}'" if options[:id]
    "<a href='#{url}' class='#{klass}'#{id}>#{caption}</a>".html_safe
  end

  def fn_button(caption, fn, options = {})
    klass = 'btn'
    klass << '_small' if options[:small]
    "<a href='\#' class='#{klass}' onclick='#{fn}; return false;'><span>#{caption}</span></a>".html_safe
  end

  def submit_and_cancel_buttons(submit_label = "Save")
    render :partial => 'shared/submit', :locals => {:submit_name => submit_label}
  end

end
