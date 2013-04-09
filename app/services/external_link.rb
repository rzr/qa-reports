require "celluloid"

class ExternalLink
  include Celluloid

  def fetch_data(service, ids, prefixed_ids)
    json = []
    ids.each do |id|
      json << {
        id:   id,
        uri:  service['link_uri'] % id
      }
    end

    {
      data: json,
      ids:  prefixed_ids
    }
  end
end
