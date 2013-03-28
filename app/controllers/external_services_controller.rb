

class ExternalServicesController < ApplicationController

  caches_action :fetch_data,
                :cache_path => Proc.new { |controller| controller.ext_service_cache_key },
                :expires_in => 1.hour

  def fetch_data
    ids  = params[:bugids]
    json = {}

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
        data = Bugzilla.fetch_data(service, plain_ids)
      when 'link'
      end

      # Now we still need to whole shebang - the returned data has all that we
      # need but we do need to return the same IDs as received (e.g. request
      # contained 1234 and BZ#1234, and even if they're the same bug we will
      # return it twice to be able to show the information on correct place
      # and not e.g. for GERRIT#1234)
      ids.each {|id|
        pid      = plain_id(id)
        json[id] = data.detect {|bug| bug[:id] == pid}
      }
    }

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
