#
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

require 'file_storage'
require 'cache_helper'
class ApiController < ApplicationController
  include CacheHelper

  before_filter :api_authentication, :except => [:reports_by_limit_and_time,
                                                 :query_items]

  def record_not_found
    head :not_found
  end

  def import_data
    errors = []
    fix_request_params(params, errors)
    return send_error("Request contained invalid files: " + errors.join(',')) if not errors.empty?

    # Check for API parameter mapping.
    ['release_version', 'target', 'testset', 'product'].each do |original|
      mapped = APP_CONFIG['api_mapping'][original]
      if mapped != '' and params.has_key?(mapped)
        params[original] = params.delete(mapped)
      end
    end

    # Map deprecated API params to current ones
    params[:hardware] ||= params[:hwproduct]
    params[:product]  ||= params[:hardware]
    params[:testset]  ||= params[:testtype]
    params[:build_id] ||= params.delete(:build_id_txt) if params[:build_id_txt]
    params.delete(:hwproduct)
    params.delete(:testtype)
    params.delete(:hardware)

    # Then fix some other possible problems -- if the request contains e.g.
    # parameter release then ReportFactory.build would try to use that
    # instead of getting a model instance
    params[:release_version] ||= params.delete(:release)
    params[:target]          ||= params.delete(:profile)

    [:release_version, :target, :product, :testset].each do |f|
      return send_error({f => "can't be blank"}) if not params[f]
    end
    return send_error({:target => "Incorrect target '#{params[:target]}'. Valid ones are: #{Profile.names.join(',')}."}) if not Profile.find_by_name(params[:target])

    begin
      @test_session = ReportFactory.new.build(params.clone)
      return send_error(errmsg_invalid_version(params[:release_version])) if not @test_session.release

      @test_session.author = current_user
      @test_session.editor = current_user

    rescue ActiveRecord::UnknownAttributeError => error
      return send_error(error.message)
    rescue Exception => error
      logger.error "ERROR: #{error.message}. Request parameters:"
      logger.error params
      return send_error(error.message)
    end

    # Check the errors
    if @test_session.errors.size > 0
      return send_error(@test_session.errors)
    end

    begin
      @test_session.save!
      @test_session.published = true
      @test_session.save!

      expire_caches_for(@test_session, true)
      expire_index_for(@test_session)

      report_url = url_for :controller => 'reports', :action => 'show', :release_version => @test_session.release.name, :target => params[:target], :testset => params[:testset], :product => params[:product], :id => @test_session.id
      render :json => {:ok => '1', :url => report_url}

    rescue ActiveRecord::RecordInvalid => invalid
      error_messages = {}
      invalid.record.errors.each do |key, value|
        # If there are more than one errors for a key return them as an array
        if invalid.record.errors[key].length > 1
          error_messages[key] ||= []
          error_messages[key] << value
        else
          error_messages[key] = value
        end
      end
      return send_error(error_messages)
    end

  end

  def merge_result
    report = MeegoTestSession.find(params[:id])
    report.merge_result_files!(params[:result_files])

    if report.errors.empty? && report.save
      report.update_attribute(:editor, current_user)
      head :ok
    else
      return send_error(report.errors)
    end
  end

  def update_result
    errors = []
    fix_request_params(params, errors)
    if !errors.empty?
      return send_error("Request contained invalid files: " + errors.join(','))
    end

    params[:updated_at] = params[:updated_at] || Time.now

    parse_err = nil

    if @report_id = params[:id].try(:to_i)
      begin
        @test_session = MeegoTestSession.find(@report_id)
        parse_err     = @test_session.update_report_result(current_user, params, true)
        @test_session.updated_at = params[:updated_at]
      rescue ActiveRecord::UnknownAttributeError, ActiveRecord::RecordNotSaved => errors
        # TODO: Could we get reasonable error messages somehow? e.g. MeegoTestCase
        # may add an error from custom results but this just has a very generic error message
        return send_error(errors.message)
      rescue Exception => error
        logger.error "ERROR: #{error.message}. Request parameters:"
        logger.error params
        return send_error(error.message)
      end

      if parse_err.present?
        return send_error(parse_err)
      end

      if @test_session.save
        expire_caches_for(@test_session, true)
        expire_index_for(@test_session)
      else
        return send_error(invalid.record.errors)
      end

      render :json => {:ok => '1'}
    end
  end

  def reports_by_limit_and_time
    begin
      raise ArgumentError, "Limit not defined" if not params.has_key? :limit_amount
      sessions = MeegoTestSession.published.order("updated_at asc").limit(params[:limit_amount])
      if params.has_key? :begin_time
        begin_time = DateTime.parse params[:begin_time]
        sessions = sessions.where('updated_at > ?', begin_time)
      end
      hashed_sessions = sessions.map { |s| ReportExporter::hashify_test_session(s) }
      render :json => hashed_sessions
    rescue ArgumentError => error
      return send_error(error.message)
    end
  end

  def query_items
    data = []

    if params[:item]
      data = case params[:item]
      when "releases"
        Release.include_root_in_json = false
        Release.select([:id, :name])
      when "targets"
        Profile.include_root_in_json = false
        Profile.select([:id, :name])
      when "results"
        MeegoTestCaseHelper.possible_results
      end
    end

    render json: data
  end

  private

  ATTACHMENT_TYPE_MAPPING = {'report' => :result_file, 'attachment' => :attachment}

  def collect_file(parameters, key, errors)
    file = parameters.delete(key)
    if (file!=nil)
      if (!file.respond_to?(:path))
        errors << "Invalid file attachment for field " + key
      end
      FileAttachment.new(:file => file, :attachment_type => ATTACHMENT_TYPE_MAPPING[key.split('.').first])
    end
  end

  def collect_files(parameters, name, errors)
    results = []
    results << collect_file(parameters, name, errors)
    parameters.keys.select { |key|
      key.starts_with?(name+'.')
    }.sort.each { |key|
      results << collect_file(parameters, key, errors)
    }
    results.compact
  end

  def errmsg_invalid_version(version)
    {:release_version => "Incorrect release version '#{version}'. Valid ones are #{Release.names.join(',')}."}
  end

  def api_authentication
      return send_error("Missing authentication token.", :forbidden) if params[:auth_token].nil?
      return send_error("Invalid authentication token.", :forbidden) unless user_signed_in?
  end

  def fix_request_params(params, errors)
    # Delete params not understood by models
    params.delete(:auth_token)
    params.delete(:controller)
    params.delete(:action)

    # Turn CSV shortcuts to markup format if found. Notice: these will not
    # overwrite the txt version if provided
    params[:issue_summary_txt]    ||= ExternalServiceHelper.convert_to_markup(params[:issue_summary_csv], APP_CONFIG['issue_summary_default_prefix'])
    params[:patches_included_txt] ||= ExternalServiceHelper.convert_to_markup(params[:patches_included_csv], APP_CONFIG['patches_included_default_prefix'])

    params.delete(:issue_summary_csv)
    params.delete(:patches_included_csv)

    # Fix result files and attachments.
    params[:result_files] ||= []
    params[:attachments]  ||= []

    # Convert uploaded files to FileAttachments
    params[:result_files] = params[:result_files].map do |f| FileAttachment.new(:file => f, :attachment_type => :result_file) end if params[:result_files]
    params[:attachments]  = params[:attachments].map  do |f| FileAttachment.new(:file => f, :attachment_type => :attachment)  end if params[:attachments]

    # Read files from the deprecated fields as well
    params[:result_files] += collect_files(params, "report", errors)
    params[:attachments]  += collect_files(params, "attachment", errors)
  end

  def send_error(errors, status = :unprocessable_entity)
    return render :json => {:ok => '0', :errors => errors}, :status => status
  end
end
