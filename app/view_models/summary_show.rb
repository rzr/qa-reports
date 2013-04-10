class SummaryShow

  delegate :id, :total_cases, :total_measured, :total_passed, :total_failed, :total_na,
           :to => :@report

  def initialize(report, build_diff=[])
    @build_diff = build_diff
    @report = report
    @counts = {'Pass' => 0, 'Fail' => 0, 'N/A' => 0, 'Measured' => 0}
    @counts.default = 0
    @total_count = 0
    report.meego_test_cases.to_a.each do |tc|
      result = tc.result_name
      @counts[result] += 1
      @total_count += 1
    end
  end

  def percentage(attribute)
    "%i%%" % ( @report.send(attribute) * 100 ).round
  end

  def count_change(attribute)
    format_change @report.change_from_previous(attribute)
  end

  def percentage_change(attribute)
    format_change( (@report.change_from_previous(attribute) * 100).round, "%" )
  end

  def change_class(attribute)
    case @report.metric_change_direction attribute
      when  0 then "unchanged"
      when  1 then "inc"
      when -1 then "dec"
    end
  end

  private

  def format_change(value, postfix="")
    return "" if value == 0
    ("%+i" % value) + postfix
  end

  def as_json(options = {})
    json = @counts.merge({'Total' => @total_count})
  end
end
