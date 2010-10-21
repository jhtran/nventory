class ConfigurationManager
  # Expects the environment to load.
  # Second argument is path to a YAML file (defaults to RAILS_ROOT/config/configuration_manager.yml).
  #
  def self.new_manager(environment=RAILS_ENV, yaml_file=File.join(RAILS_ROOT,"/config/configuration_manager.yml"))
    yaml_file = File.expand_path(yaml_file)
    if File.exist?(yaml_file)
      ConfigurationManagerHash.new_from_hash(YAML.load(ERB.new(File.read(yaml_file)).result)[environment])
    else
      ConfigurationManagerHash.new
    end
  end
end