# This file is part of meego-test-reports
#
# Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#

module ReportExporter

  EXPORTER_CONFIG    = YAML.load_file("#{Rails.root.to_s}/config/qa-dashboard_config.yml")
  POST_TIMEOUT       = 8
  POST_RETRIES_LIMIT = 3

  def self.post(data, action)
    return true if EXPORTER_CONFIG.has_key?('enabled') && EXPORTER_CONFIG['enabled'] == false

    post_data = { "token" => EXPORTER_CONFIG['token'], "report" => data }.to_json
    uri       = EXPORTER_CONFIG['host'] + EXPORTER_CONFIG['uri'] + action
    headers   = { :content_type => :json, :accept => :json }

    tries = POST_RETRIES_LIMIT
    while(tries > 0)
      Rails.logger.debug "DEBUG: ReportExporter::post qa_id:#{data['qa_id'].to_s} uri:#{uri}"
      begin
        response = RestClient::Request.execute :method  => :post,
                                               :url     => uri,
                                               :timeout => POST_TIMEOUT + 3 * (POST_RETRIES_LIMIT - tries),
                                               :open_timeout => POST_TIMEOUT + 3 * (POST_RETRIES_LIMIT - tries),
                                               :payload => post_data,
                                               :headers => headers
      rescue => e
        tries -= 1
        Rails.logger.debug "DEBUG: ReportExporter::post exception: #{e.to_s} tries left:#{(tries)}"
        Rails.logger.debug "DEBUG: ReportExporter::post too many exceptions, giving up... (qa_id:#{data['qa_id'].to_s})" if tries == 0
      else
        Rails.logger.debug "DEBUG: ReportExporter::post res: #{response.to_str}" unless response.nil?
        break
      end
    end

    return tries > 0
  end

  def self.export_test_session(json)
    post json, "update"
  end

  def self.delete_test_session_export(test_session)
    post({ "qa_id" => test_session.id }, "delete")
  end

end
