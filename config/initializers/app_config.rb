APP_CONFIG = YAML.load_file("#{::Rails.root.to_s}/config/config.yml")

APP_CONFIG['allow_empty_files'] ||= false
APP_CONFIG['custom_results']    ||= []

APP_CONFIG['custom_results'].each do |cr|
    CustomResult.find_or_create_by_name cr
end
