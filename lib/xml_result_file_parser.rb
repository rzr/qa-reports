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

      # We need serial_measurement_groups that withold the serial measurements
      groups = test_case.css('series').group_by {|s| s['group'] || s['name']}

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
        :serial_measurement_groups_attributes => groups.map do |group, series|
          # The interval unit needs to be the same for the series in a group
          # so get it from the first series
          outline = calculate_outline(series.first.css('measurement'), series.first['interval'])
          {
            :name      => group,
            :long_json => long_json_for_group(series, outline.interval_unit, maxsize=200),
            :serial_measurements_attributes => series.map do |s|
              outline = calculate_outline(s.css('measurement'), s['interval'])
              {
                :name          => s['name'],
                :short_json    => series_json(s.element_children, maxsize=40),
                :long_json     => series_json_withx(s, outline.interval_unit, maxsize=200),
                :unit          => s['unit'],
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

        end
      }
    end .index_by { |test_case| test_case[:name] }
  end

  private

  def parse_group_metrics(group)
    group.css('metric').map do |metric|
      raise Nokogiri::XML::SyntaxError.new("Missing name for a metric") unless metric['name'].present?
      raise Nokogiri::XML::SyntaxError.new("Missing value for metric #{metric['name']}") unless metric['value'].present?
      {
        :group_name => group['name'].try(:strip),
        :name       => metric['name'].try(:strip),
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

    # xUnit test (or incorrect MeeGo test but pretty hard to tell. We could
    # though look at the root element to identify MeeGo test cases)
    return MeegoTestCaseHelper::RESULT_TO_TXT[MeegoTestCase::PASS] if test_case.css('failure, error').length < 1
    return MeegoTestCaseHelper::RESULT_TO_TXT[MeegoTestCase::FAIL]
  end
end
