require 'lib/report_comparison'

class SessionComparisonController < ApplicationController
  layout "report"

  def show
    @ids = [params[:id], params[:compare_id]]
    @reports = [MeegoTestSession.find(@ids[0]), MeegoTestSession.find(@ids[1])]
    @selected_release_version = @reports[0].release_version

    @compare_cache_key = "compare_page_#{@ids[0]}_#{@ids[1]}"

    @comparison = ReportComparison.new(@reports[0], @reports[1])
  end
end