

class ExternalServicesController < ApplicationController

  caches_action :fetch_data,
                :cache_path => Proc.new { |controller| controller.ext_service_cache_key },
                :expires_in => 1.hour

  def fetch_data
    ids  = params[:ids]
    json = {}

    futures = []

    # Group the IDs by the service handling them
    ids.group_by {|id|
      service = ExternalServiceHelper.get_external_service(id)
      # Return straight away if something odd has been given
      return head :unprocessable_entity if service.nil?
      service['prefix']
    } .each {|prefix, ids|
      # Get the service for the prefix
      service = SERVICES.detect {|s| s['prefix'] == prefix}
      # Get the plain IDs to be given to the service handler
      plain_ids = ids.map {|id| plain_id(id)} .uniq

        # TODO: Better way to define what to execute?
        case service['type']
        when 'bugzilla'
          handler = Bugzilla.new
        when 'gerrit'
          handler = Gerrit.new
        when 'link'
          handler = ExternalLink.new
        end

        # We're giving the non-unique list of possibly prefixed IDs to each
        # handlers as well because the ID is needed in the same format the caller
        # sent it when constructing the complete response.
        futures << handler.future.fetch_data(service, plain_ids, ids)
    }

    futures.each do |f|
      # Celluloid future will reraise possible exceptions when calling .value
      # It seems to be very verbose at least in development, and it looks like
      # the exception would leak but fear not - they are catched.
      begin
        res = f.value
        # Now we still need to whole shebang - the returned data has all that we
        # need but we do need to return the same IDs as received (e.g. request
        # contained 1234 and BZ#1234, and even if they're the same item we will
        # return it twice to be able to show the information on correct place
        # and not e.g. for GERRIT#1234)
        res[:ids].each {|id|
          pid      = plain_id(id)
          json[id] = res[:data].detect {|item| item[:id] == pid}
        }

      rescue Errno::ETIMEDOUT
        # Do not set data to json if the request timed out - otherwise we
        # would have response like {'BZ#1234': null} which is uncalled for
      rescue Exception => e
        logger.error "Exception of type #{e.class} with message #{e.message} occurred"
      end
    end

    if json.blank?
      head :not_found
    else
      render :json => json
    end
  end

  protected

  def ext_service_cache_key
    h = Digest::SHA1.hexdigest params.to_hash.to_a.map{|k,v| if v.respond_to?(:join) then k+v.join(",") else k+v end}.join(';')
    "ext_service_#{h}"
  end

  def plain_id(str)
    /(?:[A-Z]{1,}\#{1})?(\d+)/.match(str).captures[0]
  end

end
