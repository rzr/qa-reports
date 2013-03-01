require 'nft'

class XMLResultFileParser
  include MeasurementUtils

  def parse(io)
    Nokogiri::XML(io) { |config| config.strict } .css('set, testsuite').map do |set|
      { :set => set, :name => (set['feature'] || set['name']) }
    end .inject({}) do |features, feature|
      test_cases = parse_test_cases(feature[:set])
      (features[feature[:name]] ||= {}).merge! test_cases unless test_cases.empty?
      features
    end
  end

  # Parse <metrics> section separately
  def parse_metrics(io)
    Nokogiri::XML(io) { |config| config.strict } .css('metrics group') .inject([]) do |metrics, group|
      group_metrics = parse_group_metrics(group)
      metrics.concat group_metrics
      metrics
    end
  end

  def parse_test_cases(set)
    set.css('case, testcase').map do |test_case|
      raise Nokogiri::XML::SyntaxError.new("Missing test case name") unless test_case['name'].present?
      result = get_result(test_case)

      status_code, custom_result = MeegoTestSession.map_result(result)

      {
        :name                               => test_case['name'],
        :result                             => status_code,
        :custom_result                      => custom_result,
        :comment                            => test_case['comment'] || test_case.css('failure, error').map {|f| f['message']}.join(', ') || "",
        :source_link                        => test_case['vcsurl']  || "",
        :tc_id                              => test_case['TC_ID'],
        :measurements_attributes            => test_case.xpath('./measurement').map do |measurement|
          {
            :name       => measurement['name'],
            :value      => measurement['value'].try(:to_f),
            :unit       => measurement['unit'],
            :target     => measurement['target'].try(:to_f),
            :failure    => measurement['failure'].try(:to_f),

            #TODO: Throw away and order by id
            :sort_index => 0
          }
        end ,
        :serial_measurements_attributes     => test_case.css('series').map do | series |
          outline = calculate_outline(series.css('measurement'), series['interval'])
          {
            :name          => series['name'],
            :short_json    => series_json(series.element_children, maxsize=40),
            :long_json     => series_json_withx(series, outline.interval_unit, maxsize=200),
            :unit          => series['unit'],
            :interval_unit => outline.interval_unit,
            :min_value     => outline.minval,
            :max_value     => outline.maxval,
            :avg_value     => outline.avgval,
            :median_value  => outline.median,

            #TODO: Throw away and order by id
            :sort_index    => 0
          }
        end
      }
    end .index_by { |test_case| test_case[:name] }
  end

  private

  def parse_group_metrics(group)
    group.css('metric').map do |metric|
      {
        :group_name => group['name'],
        :name       => metric['name'],
        :unit       => metric['unit'] || "",
        :value      => metric['value'],
        :chart      => metric['chart'] || false
      }
    end
  end

  def get_result(test_case)
    # MeeGo test definition
    return test_case['result'] if test_case['result'].present?

    # Google test
    if test_case['status'].present?
      return MeegoTestCaseHelper::RESULT_TO_TXT[MeegoTestCase::NA]   unless test_case['status'] == 'run'
      return MeegoTestCaseHelper::RESULT_TO_TXT[MeegoTestCase::PASS] if     test_case.css('failure, error').length < 1
      return MeegoTestCaseHelper::RESULT_TO_TXT[MeegoTestCase::FAIL]
    end

    # Otherwise
    raise Nokogiri::XML::SyntaxError.new(test_case['name'] + ": Missing result")
  end
end
