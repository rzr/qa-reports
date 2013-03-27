
require "erb"
include ERB::Util

class BugsController < ApplicationController

  caches_action :fetch_bugzilla_data,
                :cache_path => Proc.new { |controller| controller.bugzilla_cache_key },
                :expires_in => 1.hour

  def fetch_bugzilla_data
    ids       = params[:bugids]

    uri = SERVICES[0]['uri'] + ids.join(',')

    content = ""
    if not SERVICES[0]['proxy_server'].nil?
      @http = Net::HTTP.Proxy(SERVICES[0]['proxy_server'], SERVICES[0]['proxy_port']).new(SERVICES[0]['server'], SERVICES[0]['port'])
    else
      @http = Net::HTTP.new(SERVICES[0]['server'], SERVICES[0]['port'])
    end

    @http.use_ssl     = SERVICES[0]['use_ssl']
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @http.start() do |http|

      cookie = nil
      # Bugzilla integrated authentication
      if not SERVICES[0]['bugzilla_username'].nil?
        # Since Bugzilla 3.6 username and password can be given as parameters
        login_uri = "#{uri}&Bugzilla_login=#{url_encode(SERVICES[0]['bugzilla_username'])}&Bugzilla_password=#{url_encode(SERVICES[0]['bugzilla_password'])}"

        req = Net::HTTP::Get.new(login_uri)
        if not SERVICES[0]['http_username'].nil?
          req.basic_auth SERVICES[0]['http_username'], SERVICES[0]['http_password']
        end

        response = http.request(req)
        cookie   = response.to_hash['set-cookie'].collect{|ea|ea[/^.*?;/]}.join(" ")

        # If bugzilla set us a redirect URI, use that instead of the original one
        if response.header['location']
          uri = response.header['location']
        end
      end

      req = Net::HTTP::Get.new(uri)
      if not SERVICES[0]['http_username'].nil?
        req.basic_auth SERVICES[0]['http_username'], SERVICES[0]['http_password']
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
