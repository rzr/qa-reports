require "celluloid"

# Fetch patch information from Gerrit
class Gerrit
  include Celluloid

  def fetch_data(service, ids, prefixed_ids)
    content = ""

    query = ids.map {|id| "change:#{id}"} .join " OR "
    uri   = service['uri'] % query

    if not service['proxy_server'].nil?
      @http = Net::HTTP.Proxy(service['proxy_server'], service['proxy_port']).new(service['server'], service['port'])
    else
      @http = Net::HTTP.new(service['server'], service['port'])
    end

    @http.use_ssl     = service['use_ssl']
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @http.start() do |http|

      req = Net::HTTP::Get.new(URI.encode(uri))
      if not service['http_username'].nil?
        req.basic_auth service['http_username'], service['http_password']
      end

      response = http.request(req)
      if (charset = /charset=(.*)$/.match(response.header['content-type']).try(:captures)).try(:length) == 1
        response.body.force_encoding(charset[0])
      end
      content  = response.body
    end

    json = []

    # Each line in the content is a single JSON object so split and parse
    # line by line... https://code.google.com/p/gerrit/issues/detail?id=1040
    content.split(/\r?\n/).each do |row|
      data = JSON.parse row
      if data.has_key?('number')
        json << {
          id:       data['number'],
          title:    data['subject'],
          status:   data['status'],
          uri:      data['url'],
          service:  'gerrit'
        }
      end
    end

    {
      data: json,
      ids: prefixed_ids
    }
  end
end
