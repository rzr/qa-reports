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

  def self.fix_summary(summary)
    {
      total_cases:    summary['Total'],
      total_pass:     summary['Passed'] || summary['Pass'],
      total_fail:     summary['Failed'] || summary['Fail'],
      total_na:       summary['N/A'],
      total_measured: summary['Measured']
    }
  end

  # Fix the JSON values to match those expected by QA Dashboard. Once QA Dashboard
  # is updated this can be removed but keep these services compatible for now.
  # Comments are not set even if they used to be because it seems that QA Dashboard
  # does not use them currently.
  def self.fix_values(json)
    json[:hardware] = json[:product]
    json[:testtype] = json[:testset]

    json.merge!(ReportExporter.fix_summary(json[:summary]))
    json[:features].each do |f|
      f.merge!(ReportExporter.fix_summary(f[:summary]))

      f[:cases] = f[:testcases]
      f[:cases].each do |tc|
        tc[:bugs] = tc[:bugs].map {|bug| bug[:id]}
      end
    end
    json
  end

  def self.post(data, action)
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
    post ReportExporter.fix_values(json), "update"
  end

  def self.delete_test_session_export(test_session)
    post({ "qa_id" => test_session.id }, "delete")
  end

end
