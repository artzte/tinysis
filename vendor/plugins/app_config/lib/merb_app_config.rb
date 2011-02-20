require 'application_config/deep_merge' unless defined?(DeepMerge)
require 'application_config/config_builder'
require 'application_config/view_helpers'

# make sure we're running inside Merb
if defined?(Merb::Plugins)
  # Merb gives you a Merb::Plugins.config hash...feel free to put your stuff in your piece of it
  Merb::Plugins.config[:app_config] = {
    :auto_reload => Merb.env?(:development),
    :view_helpers => true,
    :paths => [
      "#{Merb.root}/config/app_config.yml",
      "#{Merb.root}/config/app_config/settings.yml",
      "#{Merb.root}/config/app_config/#{Merb.env}.yml",
      "#{Merb.root}/config/environments/#{Merb.env}.yml",
      "#{Merb.root}/config/assets.yml",
      "#{Merb.root}/config/javascripts.yml",
      "#{Merb.root}/config/stylesheets.yml"
    ]
  }
  
  Merb::BootLoader.before_app_loads do
    if defined?(::AppConfig)
      AppConfig.reload!
    else
      ::AppConfig = ApplicationConfig::ConfigBuilder.load_files(
        :paths =>  Merb::Plugins.config[:app_config][:paths].to_a,
        :expand_keys => [:javascripts, :stylesheets],
        :root_path => Merb.root
      )
    end

    if Merb::Plugins.config[:app_config][:view_helpers]
      Merb::Controller.send(:include, ApplicationConfig::ViewHelpers)
    end
    
    if Merb::Plugins.config[:app_config][:auto_reload]
      Merb.logger.info "[AppConfig] Auto reloading AppConfig on every request."
      Merb.logger.info "[AppConfig] Set via Merb::Plugins.config[:app_config][:auto_reload]"
      
      # add before filter
      ::Merb::Controller.before do
        AppConfig.reload!
      end
    end
  end
  
  Merb::BootLoader.after_app_loads do
  end
  
  Merb::Plugins.add_rakefiles "merbtasks"
end