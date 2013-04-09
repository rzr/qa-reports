require "erb"
require "celluloid"
include ERB::Util

# Fetch bug information from Bugzilla
class Bugzilla
  include Celluloid

  # Fetch bug information for given ids from given service (from
  # external.services.yml configuration)
  def fetch_data(service, ids, prefixed_ids)
    uri = service['uri'] % ids.join(',')

    content = ""
    if not service['proxy_server'].nil?
      @http = Net::HTTP.Proxy(service['proxy_server'], service['proxy_port']).new(service['server'], service['port'])
    else
      @http = Net::HTTP.new(service['server'], service['port'])
    end

    @http.use_ssl     = service['use_ssl']
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @http.start() do |http|

      cookie = nil
      # Bugzilla integrated authentication
      if not service['bugzilla_username'].nil?
        # Since Bugzilla 3.6 username and password can be given as parameters
        login_uri = "#{uri}&Bugzilla_login=#{url_encode(service['bugzilla_username'])}&Bugzilla_password=#{url_encode(service['bugzilla_password'])}"

        req = Net::HTTP::Get.new(login_uri)
        if not service['http_username'].nil?
          req.basic_auth service['http_username'], service['http_password']
        end

        response = http.request(req)
        cookie   = response.to_hash['set-cookie'].collect{|ea|ea[/^.*?;/]}.join(" ")

        # If bugzilla set us a redirect URI, use that instead of the original one
        if response.header['location']
          uri = response.header['location']
        end
      end

      req = Net::HTTP::Get.new(uri)
      if not service['http_username'].nil?
        req.basic_auth service['http_username'], service['http_password']
      end

      if not cookie.nil?
        req['Cookie'] = cookie
      end

      response = http.request(req)
      if (charset = /charset=(.*)$/.match(response.header['content-type']).try(:captures)).try(:length) == 1
        response.body.force_encoding(charset[0])
      end
      content  = response.body
    end

    json = []
    begin
      # Don't parse headers
      csv = CSV.parse(content, :headers => true)
    rescue CSV::MalformedCSVError => e
      logger.error e.message
      logger.info  "ERROR: MALFORMED BUGZILLA DATA"
      logger.info  content
      csv = nil
    end

    # Convert to a better format
    # TODO: Some day when we do have more than just links and Bugzilla,
    # the JSON keys should make sense in more generic manner
    unless csv.nil?
      csv.each do |row|
        json << {
          id:         row[0],
          title:      row[1],
          status:     row[2],
          resolution: row[3],
          uri:        service['link_uri'] + row[0]
        }
      end
    end

    {
      data: json,
      ids:  prefixed_ids
    }
  end
end
