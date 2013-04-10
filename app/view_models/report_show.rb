class ReportShow < SummaryShow

  delegate :build_id, :created_at, :max_feature_cases, :product, :release, :profile, :testset, :title,
           :to => :@report

  def initialize(report, build_diff=[])
    super(report, build_diff)
  end

  def features
    @features ||= @report.features.map { |feature| FeatureShow.new(feature, @build_diff) }
  end

  def non_empty_features
    @non_empty_features ||= @report.non_empty_features.map { |feature| FeatureShow.new(feature, @build_diff) }
  end

  def as_json(options = {})
    json = {
      release:  @report.release.try(:name) || 'N/A',
      profile:  @report.profile.try(:name) || 'N/A',
      testset:  @report.testset,
      product:  @report.product,
      title:    @report.title,
      summary:  super,
      features: features.map {|f| f.as_json(options)},
      prev_session_id: @report.prev_session.nil? == false ? @report.prev_session.id : ''
    }

    json[:qa_id] = @report.id if options[:include_db_id]

    if options[:include_dates]
      json[:created_at] = @report.created_at.utc
      json[:updated_at] = @report.updated_at.utc
      json[:tested_at]  = @report.tested_at.utc
      json[:weeknum]    = Date.parse(@report.tested_at.to_date.to_s).cweek()
    end

    if options[:include_text_fields]
      json[:objective]        = @report.objective_txt
      json[:build]            = @report.build_txt
      json[:build_id]         = @report.build_id
      json[:environment]      = @report.environment_txt
      json[:qa_summary]       = @report.qa_summary_txt
      json[:issue_summary]    = @report.issue_summary_txt
      json[:patches_included] = @report.patches_included_txt
    end

    # Scan external service IDs from all text fields
    if options[:scan_text_fields]

    end

    json
  end

end
