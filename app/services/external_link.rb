module ExternalLink

  def self.fetch_data(service, ids)
    json = []
    ids.each do |id|
      json << {
        id:   id,
        uri:  service['link_uri'] % id
      }
    end
    json
  end
end
