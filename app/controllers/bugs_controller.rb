
require "erb"
include ERB::Util

class BugsController < ApplicationController

  caches_action :fetch_bugzilla_data,
                :cache_path => Proc.new { |controller| controller.bugzilla_cache_key },
                :expires_in => 1.hour

  def fetch_bugzilla_data
    ids       = params[:bugids]

    uri = BUGZILLA_CONFIG['uri'] + ids.join(',')

    content = ""
    if not BUGZILLA_CONFIG['proxy_server'].nil?
      @http = Net::HTTP.Proxy(BUGZILLA_CONFIG['proxy_server'], BUGZILLA_CONFIG['proxy_port']).new(BUGZILLA_CONFIG['server'], BUGZILLA_CONFIG['port'])
    else
      @http = Net::HTTP.new(BUGZILLA_CONFIG['server'], BUGZILLA_CONFIG['port'])
    end

    @http.use_ssl     = BUGZILLA_CONFIG['use_ssl']
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @http.start() do |http|

      cookie = nil
      # Bugzilla integrated authentication
      if not BUGZILLA_CONFIG['bugzilla_username'].nil?
        # Since Bugzilla 3.6 username and password can be given as parameters
        login_uri = "#{uri}&Bugzilla_login=#{url_encode(BUGZILLA_CONFIG['bugzilla_username'])}&Bugzilla_password=#{url_encode(BUGZILLA_CONFIG['bugzilla_password'])}"

        req = Net::HTTP::Get.new(login_uri)
        if not BUGZILLA_CONFIG['http_username'].nil?
          req.basic_auth BUGZILLA_CONFIG['http_username'], BUGZILLA_CONFIG['http_password']
        end

        response = http.request(req)
        cookie   = response.to_hash['set-cookie'].collect{|ea|ea[/^.*?;/]}.join(" ")

        # If bugzilla set us a redirect URI, use that instead of the original one
        if response.header['location']
          uri = response.header['location']
        end
      end

      req = Net::HTTP::Get.new(uri)
      if not BUGZILLA_CONFIG['http_username'].nil?
        req.basic_auth BUGZILLA_CONFIG['http_username'], BUGZILLA_CONFIG['http_password']
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

    begin
      json = CSV.parse(content)
      # TODO: Should render json instead of CSV
      render :json => json
    rescue CSV::MalformedCSVError => e
      logger.error e.message
      logger.info  "ERROR: MALFORMED BUGZILLA DATA"
      logger.info  content
      head :not_found
    end
  end

  protected

  def bugzilla_cache_key
    h = Digest::SHA1.hexdigest params.to_hash.to_a.map{|k,v| if v.respond_to?(:join) then k+v.join(",") else k+v end}.join(';')
    "bugzilla_#{h}"
  end

end
