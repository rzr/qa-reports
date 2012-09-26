
def measurement_value(measurement)
  measurement.split.first
end

def measurement_unit(value, target)
  # TODO: use this after we can store null as value:
  # value.split.second || target.split.second
  value.split.second || "dummy"
end

Given %r/^there's an existing report$/ do
  report = FactoryGirl.build(:test_report_wo_features, :tested_at => '2011-09-01')
  report.features << FactoryGirl.build(:feature_wo_test_cases)
  report.features.first.meego_test_cases <<
    FactoryGirl.build(:test_case, :name => 'Test Case 1', :result => MeegoTestCase::PASS, :comment => 'This comment should be used as a template') <<
    FactoryGirl.build(:test_case, :name => 'Test Case 2', :result => MeegoTestCase::PASS, :comment => 'This comment should be overwritten with empty comment')

  report.save!
end

Given %r/^there's a "([^"]*)" report created "([^"]*)" days ago$/ do |categories, count|
  release, profile, testset, product = categories.split '/'
  release, profile, testset, product = nil, release, profile, testset if !product
  report  = FactoryGirl.build(:test_report,
    :release => (release ? Release.find_by_name(release) : Release.first),
    :profile => Profile.find_by_name(profile),
    :testset => testset,
    :product => product,
    :tested_at => count.to_i.days.ago)
  report.save!
end

Given %r/^I view a report with results: (\d+) Passed, (\d+) Failed, (\d+) N\/A$/ do |passed, failed, na|
  report = FactoryGirl.build(:test_report_wo_features)
  report.features << FactoryGirl.build(:feature_wo_test_cases)
  report.features.first.meego_test_cases << FactoryGirl.build_list(:test_case, passed.to_i, :result =>  MeegoTestCase::PASS)
  report.features.first.meego_test_cases << FactoryGirl.build_list(:test_case, failed.to_i, :result =>  MeegoTestCase::FAIL)
  report.features.first.meego_test_cases << FactoryGirl.build_list(:test_case, na.to_i, :result =>  MeegoTestCase::NA)
  report.save!
end

Then %r/^I should see Result Summary:$/ do |table|
  visit report_path MeegoTestSession.first
  with_scope("#test_result_overview") do
    table.hashes.each do |hash|
      actual = find(:xpath, "//tr[td='#{hash[:Title]}']").find(":nth-child(2)").text
      actual.should eql(hash[:Result]), "Expected '#{hash[:Title]}' to be #{hash[:Result]}\nGot #{actual}\n"
    end
  end
end

And %r/^I should not see in Result Summary:$/ do |table|
  #visit report_path MeegoTestSession.first
  with_scope("#test_result_overview") do
    table.hashes.each do |hash|
      page.should have_no_selector(:xpath, "//tr[td='#{hash[:Title]}']"), "Expected no '#{hash[:Title]}'\nBut found one."
    end
  end
end

Given %r/^I view a report with results:$/ do |table|
  report = FactoryGirl.build(:test_report_wo_features)
  report.features << FactoryGirl.build(:feature_wo_test_cases)

  table.hashes.each do |hash|
    result, custom_result = MeegoTestSession.map_result(hash[:Result])
    report.features.first.meego_test_cases << FactoryGirl.build(:test_case,
      :result =>  result,
      :measurements => [FactoryGirl.build(:meego_measurement,
        :value   => measurement_value(hash[:Value]),
        :target  => measurement_value(hash[:Target]),
        :failure => measurement_value(hash[:Fail_limit]),
        :unit    => measurement_unit(hash[:Value], hash[:Target]) )])
  end

  report.save!
end

Given %r/^I create a new test report with same test cases$/ do
  RESULT_CSV = 'Category,Check points,Notes (bugs),Pass,Fail,N A
Bluetooth,Test Case 1,,1,0,0
Bluetooth,Test Case 2,,0,1,0'

  tmp = Tempfile.new('result_file')
  tmp << RESULT_CSV
  file = ActionDispatch::Http::UploadedFile.new(:tempfile => tmp, :filename => 'result.csv')
  report_attributes = MeegoTestSession.first.attributes.merge(:tested_at => '2011-09-02')
  report_attributes[:result_files_attributes] = [{:file => file, :attachment_type => :result_file}]

  report = ReportFactory.new.build(report_attributes)
  report.save!
  report.prev_session.features.count.should == 1
end

Then %r/^I should see the test case comments from the previous test report if the result hasn't changed$/ do
  report = MeegoTestSession.find_by_tested_at('2011-09-02')
  visit report_path(report)
  click_link_or_button('+ see 1 passing tests')
  find_testcase_row("Test Case 1").should have_content("This comment should be used as a template")
  find_testcase_row("Test Case 2").should have_no_content("This comment should be overwritten with empty comment")
end

When %r/^I view the latest report$/ do
  visit report_path(MeegoTestSession.latest)
end

When %r/^I request the report summary as json$/ do
  response = get "/1.2/Core/automated/N900.json"
  json = ActiveSupport::JSON.decode(response.body)

  json.length.should == 1
  json[0]['id'].should_not be_nil

  response = get "/1.2/Core/automated/N900/#{json[0]['id']}.json"
  @json = ActiveSupport::JSON.decode(response.body)
end

require 'pp'

Then %r/^I should get the summary for the whole report$/ do
  summary = @json['summary']

  summary['total'].should == 9
  summary['passed'].should == 3
  summary['failed'].should == 4
  summary['na'].should == 2
end

Then %r/^I should get the summary for each feature$/ do
  @json['features'].length.should == 4
  @json['features'].each do |feature|
    case feature['name']
    when 'Contacts'
      feature['total'].should == 1
      feature['passed'].should == 1
      feature['failed'].should == 0
      feature['na'].should == 0
    when 'Dialer'
      feature['total'].should == 2
      feature['passed'].should == 0
      feature['failed'].should == 0
      feature['na'].should == 2
    when 'Audio'
      feature['total'].should == 2
      feature['passed'].should == 0
      feature['failed'].should == 2
      feature['na'].should == 0
    when 'Home screen'
      feature['total'].should == 4
      feature['passed'].should == 2
      feature['failed'].should == 2
      feature['na'].should == 0
    end
  end
end

