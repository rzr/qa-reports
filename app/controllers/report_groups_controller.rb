require 'graph'

class ReportGroupsController < ApplicationController

  def show
    @show_rss = true

    args = [release.name, profile.name, testset, product]

    # Try to find the closest matching view to show - judging from the user
    # feedback the most common scenario for getting a 404 is that you're
    # looking at reports from branch W1/X/Y/Z and clicking to another release
    # version W2 which does not have reports for X/Y/Z. So instead of giving
    # a 404 try if it has reports for X/Y, then Y, and finally redirect to
    # index page of W2.
    3.downto(1) do |i|
      begin
        @group_report = ReportGroupViewModel.new(*args)
        break
      rescue ActiveRecord::RecordNotFound => e
        args[i] = nil
      end
    end

    if @group_report.nil?
      redirect_to root_path
      return
    end

    @monthly_data = @group_report.report_range_by_month(0..39).to_json
    respond_to do |format|
      format.html
      format.json { render json: @group_report.all_reports.map { |r|
        json = r.as_json root:false, only:[:id, :title, :tested_at]
        json.merge!(url: url_for(controller: 'reports', action: 'show', release_version: r.release.name, target: r.profile.name, testset: r.testset, product: r.product, id: r.id))
        json
      }, :callback => params[:callback]}
    end
  end

  def report_page
    @reports_per_page = 40
    @page = [1, params[:page].to_i].max rescue 1
    @page_index = @page - 1

    @group_report = ReportGroupViewModel.new(release.name, profile.name, testset, product)
    offset = @reports_per_page * @page_index
    @report_range = (offset..offset + @reports_per_page - 1)

    unless @group_report.reports_by_range(@report_range).empty?
      render :json => @group_report.report_range_by_month(@report_range)
    else
      render :text => ''
    end
  end

end
