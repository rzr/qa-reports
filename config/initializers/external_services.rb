ext_services_cfg_file = "#{::Rails.root.to_s}/config/external.services.yml"
bugzilla_cfg_file     = "#{::Rails.root.to_s}/config/bugzilla.yml"

# Using the new configuration file
if File.exists?(ext_services_cfg_file)
  SERVICES = YAML.load_file(ext_services_cfg_file)
# Using Bugzilla configuration file
else
  bugzilla_cfg = YAML.load_file(bugzilla_cfg_file)
  # Reformat the configuration a bit so it looks the same as loading a single
  # service from the new configuration file format.
  bugzilla_cfg['type']    = 'bugzilla'
  bugzilla_cfg['default'] = true
  bugzilla_cfg['prefix']  = ''

  SERVICES = [bugzilla_cfg]
end
