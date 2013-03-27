module ExternalServiceHelper

  # Get prefix and ID from user entered ID
  def self.get_prefix_id(id)
    # Bugs are of format [[PREFIX#ID]] or [[ID]], or PREFIX#ID or ID
    prefix, id = /(?:\[\[)?([A-Z]{1,}\#{1})?(\d+)(?:\[\[)?/.match(id).try(:captures)
    return prefix, id
  end

  # Get the service to whatever service given ID points to
  def self.get_external_service(id)
    prefix, id = ExternalServiceHelper.get_prefix_id(id)
    return nil if id.blank?

    # No prefix, return the default service right away
    return DEFAULT_SERVICE if prefix.blank?

    prefix.sub! '#', ''
    SERVICES.detect{|s| s['prefix'] == prefix} || DEFAULT_SERVICE
  end

  # Get URL to given ID in whatever service it points to
  def self.get_external_url(id)
    service = ExternalServiceHelper.get_external_service(id)
    return '' if service.nil?

    prefix, id = ExternalServiceHelper.get_prefix_id(id)
    service['link_uri'] + id
  end

end
