Given %r/^I am a user with a REST authentication token$/ do
  if !User.find_by_email('resting@man.net')
    FactoryGirl.create(:user,
      :name                  => 'John Restless',
      :email                 => 'resting@man.net',
      :password              => 'secretpass',
      :password_confirmation => 'secretpass',
      :authentication_token  => 'foobar')
  end
end

Given "the client has sent a request with a defined test objective" do
  step %{the client sends a request with defined test objective}
  # Needed in order to get different time stamps for current - previous matching
  sleep 1
end

Given /^the client has sent a report with test case comments$/ do
  step %{the client sends file "features/resources/single_case_comment.xml" via the REST API}
  sleep 1
end

def api_import( params )
  post "api/import", params
end

When "the client sends a basic test result file" do
  step %{the client sends file "features/resources/sim.xml" via the REST API}
end

When "the client sends a basic test result file via deprecated API" do
  step %{the client sends file "features/resources/sim.xml" via the deprecated REST API}
end

When "the client sends a basic test result file via custom mapped API" do
  step %{the client sends file "features/resources/sim.xml" via custom mapped REST API}
end

When "the client sends a report with tests without features" do
  step %{the client sends file "spec/fixtures/no_features.xml" via the REST API}
end

When "the client sends a basic test result file with option to hide summary" do
  @response = api_import @default_api_opts.merge({"hide_summary" => true})
end

When "the client sends a test result with metrics with option to hide metrics" do
  @response = api_import @default_api_opts.merge({"hide_metrics" => true,
    "result_files[]" => Rack::Test::UploadedFile.new("features/resources/xml_with_metrics.xml", "text/xml")})
end

When "the client sends file with a bug ID in issue summary" do
  @response = api_import @default_api_opts.merge({"issue_summary_txt" => "* [[1234]]"})
end

When "the client sends file with a bug ID with prefix in issue summary" do
  @response = api_import @default_api_opts.merge({"issue_summary_txt" => "* [[BZ#1234]]"})
end

When "the client sends file with bugs to two services in issue summary" do
  @response = api_import @default_api_opts.merge({"issue_summary_txt" => "* [[BZ#1234]] [[MOZ#1234]]"})
end

When "the client sends file with URIs to bugs in two services in issue summary" do
  @response = api_import @default_api_opts.merge({"issue_summary_txt" =>
    "* https://bugs.merproject.org/show_bug.cgi?id=1234 https://bugzilla.mozilla.org/show_bug.cgi?id=1234"})
end

When "the client sends file patch ID in issue summary" do
  @response = api_import @default_api_opts.merge({"issue_summary_txt" => "* [[GER#1234]]"})
end

When "the client sends file with URI to Gerrit patch in issue summary" do
  @response = api_import @default_api_opts.merge({"issue_summary_txt" => "* http://review.cyanogenmod.org/#/c/1234/"})
end

# Note: this must use the API parameters for the current API version. There
# are other methods for using deprecated parameters.
When %r/^the client sends file "([^"]*)" via the REST API$/ do |file|
  # @default_api_opts defined in features/support/hooks.rb
  @response = api_import @default_api_opts.merge({
    "result_files[]" => Rack::Test::UploadedFile.new("#{file}", "text/xml")
  })
end

When %r/^the client sends file "([^"]*)" via the deprecated REST API$/ do |file|
  data = @default_api_opts
  data.delete('result_files[]')
  data = data.merge({
    "report.1" => Rack::Test::UploadedFile.new("#{file}", "text/xml")
  })
  @response = api_import data
end

# The first API had hwproduct and testtype
When "the client sends a basic test result file with deprecated parameters" do
  @response = api_import @default_version_1_api_opts.merge({
    "report.1" => Rack::Test::UploadedFile.new("features/resources/sim.xml", "text/xml")
  })
end

# The 2nd API had "hardware"
When "the client sends a basic test result file with deprecated product parameter" do
  @response = api_import @default_version_2_api_opts.merge({
    "report.1" => Rack::Test::UploadedFile.new("features/resources/sim.xml", "text/xml")
  })
end

# Custom mapped API params
When %r/^the client sends file "([^"]*)" via custom mapped REST API$/ do |file|
  @response = api_import @mapped_api_opts.merge({
    "result_files[]" => Rack::Test::UploadedFile.new("#{file}", "text/xml")
  })
end

When %r/^the client sends reports "([^"]*)" via the REST API to test set "([^"]*)" and product "([^"]*)"$/ do |files, testset, hardware|
  data = @default_api_opts.merge({
    "testset" => testset,
    "product" => hardware
  })

  files.split(',').each_with_index do |file, index|
    data["report."+(index+1).to_s] = Rack::Test::UploadedFile.new(file, "text/xml")
  end

  @response = api_import data
end

When %r/^the client sends files with attachments$/ do
  @response = api_import @default_api_opts.merge({
      "report.1"        => Rack::Test::UploadedFile.new("features/resources/sim.xml", "text/xml"),
      "report.2"        => Rack::Test::UploadedFile.new("features/resources/bluetooth.xml", "text/xml"),
      "attachment.1"    => Rack::Test::UploadedFile.new("app/assets/images/white_transp_70.png", "image/png"),
      "attachment.2"    => Rack::Test::UploadedFile.new("app/assets/images/icon_alert.gif", "image/gif"),
  })
end

# This is used in test session listing tests
When "the client sends three CSV files" do
  step %{the client sends file "features/resources/short1.csv" via the REST API}
  step %{the client sends file "features/resources/short2.csv" via the REST API}
  step %{the client sends file "features/resources/short3.csv" via the REST API}
  # Update here, no need to have a step in the feature for this
  step %{session "short1.csv" has been modified at "2011-01-01 01:01"}
  step %{session "short2.csv" has been modified at "2011-02-01 01:01"}
  step %{session "short3.csv" has been modified at "2011-03-01 01:01"}
end

When "the client sends file with custom results" do
  step %{the client sends file "features/resources/custom_statuses.xml" via the REST API}
end

When "the client sends partial file with custom results" do
  step %{the client sends file "features/resources/custom_statuses_subset.xml" via the REST API}
end

When "the client sends googletest result file" do
  step %{the client sends file "features/resources/googletest.xml" via the REST API}
end

When "the client sends xUnit result file" do
  step %{the client sends file "features/resources/xunit.xml" via the REST API}
end

When "the client sends result file with metrics" do
  step %{the client sends file "features/resources/xml_with_metrics.xml" via the REST API}
end

When(/^the client sends result file with grouped serial measurements$/) do
  step %{the client sends file "features/resources/grouped-serial-measurements.xml" via the REST API}
end

When %r/^the client sends a request with string value instead of a file$/ do
    @response = api_import @default_api_opts.merge("report.1" => "Foo!")
end

When %r/^the client sends a request without file$/ do
  @default_api_opts.delete("result_files[]")
  @response = api_import @default_api_opts
end

When %r/^the client sends a request without a target profile$/ do
  @default_api_opts.delete("target")
  @response = api_import @default_api_opts
end

When "the client sends a request with invalid release version" do
  @default_api_opts["release_version"] ="foo"
  @response = api_import @default_api_opts
end

When "the client sends a request with invalid target profile" do
  @default_api_opts["target"] ="Foo"
  @response = api_import @default_api_opts
end

When "the client sends a request with invalid product" do
  @default_api_opts["product"] ="N900/ce"
  @response = api_import @default_api_opts
end

When "the client sends a request containing invalid extra parameter" do
  step %{the client sends a request with optional parameter "foobar" with value "1"}
end

When "the client sends a request with a defined title" do
  step %{the client sends a request with optional parameter "title" with value "My Test Report"}
end

When "the client sends a request with defined test objective" do
  step %{the client sends a request with optional parameter "objective_txt" with value "To notice regression"}
end

When "the client sends a request with defined build information" do
  step %{the client sends a request with optional parameter "build_txt" with value "foobar-image.bin"}
end

When "the client sends a request with defined build ID" do
  step %{the client sends a request with optional parameter "build_id_txt" with value "1234.78a"}
end

When "the client sends a request with defined environment information" do
  step %{the client sends a request with optional parameter "environment_txt" with value "Laboratory environment"}
end

When "the client sends a request with defined quality summary" do
  step %{the client sends a request with optional parameter "qa_summary_txt" with value "Ready to ship"}
end

When "the client sends a request with defined issue summary" do
  step %{the client sends a request with optional parameter "issue_summary_txt" with value "No major issues found"}
end

When %r/^the client sends a request with optional parameter "([^"]*)" with value "([^"]*)"$/ do |opt, val|
  @response = api_import @default_api_opts.merge({
    "report.1"        => Rack::Test::UploadedFile.new("features/resources/sim.xml", "text/xml"),
    opt               => val
  })
end

When "the client sends a request with all optional parameters defined" do
  @response = api_import @default_api_opts_all
end

When "the client sends a request with CSV parameters for issues summary and patches included" do
  @response = api_import @defalt_api_opts_csv_shortcut
end

When "the client sends a request with an ID only in patches included CSV" do
  @response = api_import @default_api_opts.merge({"patches_included_csv" => "1234"})
end

When /^the client sends matching test case without comments$/ do
    step %{the client sends file "features/resources/single_case_without_comment.xml" via the REST API}
end

When /^the client sends matching test case without comments with comment copy disabled$/ do
  @response = api_import @default_api_opts.merge({
    "result_files[]" => Rack::Test::UploadedFile.new("features/resources/single_case_without_comment.xml", "text/xml"),
    "copy_template_values" => false
  })
end

When %r/^I view the latest report "([^"]*)"/ do |report_string|
  #TODO: Use scopes
  version, target, test_type, product = report_string.downcase.split('/')
  report = MeegoTestSession.joins([:release, :profile]).where(:releases => {:name => version}, :profiles => {:name => target}, :product => product, :testset => test_type).order("created_at DESC").first
  raise "report not found with parameters #{version}/#{target}/#{product}/#{test_type}!" unless report
  visit("/#{version}/#{target}/#{test_type}/#{product}/#{report.id}")
end

When "I download a list of sessions with begin time given" do
  step %{I download "/api/reports?limit_amount=1&begin_time=2011-01-10%2012:00"}
end

When "I download a list of sessions without a begin time" do
  step %{I download "/api/reports?limit_amount=1"}
end

When %r/^I download "([^"]*)"$/ do |file|
  @response = get file
end

When %r/^I view the (updated )?report$/ do |unused_param|
  step %{I view the report "1.2/Core/Automated/N900"}
end

When %r/^I request API "(.*?)"$/ do |uri|
  response = get uri
  @json = ActiveSupport::JSON.decode response.body
end

def check_query_api_json (items)
  @json.should_not be_nil
  @json.length.should == items.length
  items.each do |item|
    elem = @json.to_a.detect {|e| e['name'] == item.name}
    elem.should_not be_nil
  end
end

Then %r/^I should get all releases existing in database$/ do
  releases = Release.all()
  check_query_api_json releases
end

Then %r/^I should get all targets existing in database$/ do
  targets = Profile.all()
  check_query_api_json targets
end

Then %r/^I should get all allowed test results$/ do
  @json.should_not be_nil
  results = ['Fail', 'N/A', 'Pass', 'Measured'] # Builtin
  results.concat APP_CONFIG['custom_results']
  @json.length.should == results.length
  results.should =~ @json.to_a
end

Then %r/^I should be able to view the latest created report$/ do
  step %{I view the latest report "1.2/Core/Automated/N900"}
end

Then %r/^I should be able to view the created report$/ do
  step %{I view the report "1.2/Core/Automated/N900"}
end

# For uploading multiple files (sim and bluetooth)
Then %r/^I should see names of the two features/ do
  step %{I should see "SIM"}
  step %{I should see "BT"}
end

# For uploading attachments
Then "I should see the uploaded attachments" do
  list = "#attachment_drag_drop_area .file_list"
  step %{I should see "white_transp_70.png" within "#{list}"}
  step %{I should see "icon_alert.gif" within "#{list}"}
end

# Attachments as imgs when inlining enabled
Then /^I should see the two attached images$/ do
  img = "//div[@id='attachment_drag_drop_area']//img"
  page.should have_xpath("#{img}[contains(@src, 'white_transp_70.png')]")
  page.should have_xpath("#{img}[contains(@src, 'icon_alert.gif')]")
end

# Checking for a feature named N/A when had cases without a feature
Then "I should see an unnamed feature section" do
  step %{I should see "N/A" within ".feature_name"}
end

# Checking the amount of cases match when we sent the file with test
# cases without features
Then "I should see the correct amount of test cases without a feature" do
  step %{I should see "8" within "td.total"}
end

Then "I should see the defined test objective" do
  step %{I should see "To notice regression"}
end

Then "I should see the defined build information" do
  step %{I should see "foobar-image.bin"}
end

Then "I should see the defined build ID" do
  step %{I should see "1234.78a"}
end

Then "I should see the defined environment information" do
  step %{I should see "Laboratory environment"}
end

Then "I should see the defined quality summary" do
  step %{I should see "Ready to ship"}
end

Then "I should see the defined issue summary" do
  step %{I should see "No major issues found"}
end

Then "I should see the defined patches included" do
  step %{I should see "No patches included"}
end

Then "I should see the objective of previous report" do
  step %{I should see the defined test objective}
end

Then "I should see the defined report title" do
  step %{I should see "My Test Report"}
end

Then "I should see a list of issues in issue summary" do
  step %{I should see link to bug "9353" within "body"}
end

Then "I should see a list of patches in patches included" do
  step %{I should see link to bug "5678" within "body"}
end

Then %r/^I should see test cases with result Blocked/ do
  step %{I should see "Blocked"}
end

Then "I should see the defined test cases" do
  step %{I should see "NonContradiction_2"}
  step %{I should see "Addition"}
  step %{I should see "Value of: add(1, 1)"}
end

Then "I should see the test cases from xUnit result file" do
  step %{I should really see "passing_test"}
  step %{I should really see "test_with_failures"}
  step %{I should really see "test_with_errors"}
end

Then /^I should see a link to Bugzilla$/ do
  step %{I should see link to bug "https://bugs.merproject.org/show_bug.cgi?id=1234" within "body"}
end

Then /^I should see a link to Mozilla Bugzilla$/ do
  step %{I should see link to bug "https://bugzilla.mozilla.org/show_bug.cgi?id=1234" within "body"}
end

Then /^I should see a link to Gerrit$/ do
  step %{I should see link to bug "http://review.cyanogenmod.org/#/c/1234/" within "body"}
end

Then /^I should see the comment from previous test report$/ do
  step %{I should see "Comment for simple test case"}
end

Then /^I should not see the comment from previous test report$/ do
  step %{I should not see "Comment for simple test case"}
end

Then "the upload succeeds" do
  @response.status.should == 200
  step %{the REST result "ok" is "1"}
end

Then "the upload fails" do
  @response.status.should == 422
  step %{the REST result "ok" is "0"}
end

Then "the result complains about invalid file" do
  step %{the REST result "errors" is "Request contained invalid files: Invalid file attachment for field report.1"}
end

Then "the result complains about missing file" do
  step %{the REST result "errors|result_files" is "can't be blank"}
end

Then "the result complains about missing target profile" do
  step %{the REST result "errors|target" is "can't be blank"}
end

Then "the result complains about invalid release version" do
  step %{the REST result "errors|release_version" is "Incorrect release version 'foo'. Valid ones are 1.2,1.1,1.0."}
end

Then "the result complains about invalid target profile" do
  step %{the REST result "errors|target" is "Incorrect target 'Foo'. Valid ones are: Core,Handset,Netbook,IVI,SDK."}
end

Then "the result complains about invalid product" do
  step %{the REST result "errors|product" is "Incorrect product. Please use only characters A-Z, a-z, 0-9, spaces and these special characters: , : ; - _ ( )"}
end

Then "the result complains about invalid parameter" do
  step %{the REST result "errors" is "unknown attribute: foobar"}
end

Then "the result complains about invalid custom result" do
  step %{the REST result "errors" contains "Custom result Invalid custom result in testcase NFT-BT-Device_Scan"}
end

Then %r/^the REST result "([^"]*)" is "([^"]*)"$/ do |key, value|
  json = ActiveSupport::JSON.decode(@response.body)
  key.split('|').each { |item| json = json[item] }
  assert_msg = "Expected response '#{key}' with value \"#{value}\"\nGot value: \"#{json}\""
  assert_msg = "Expected response '#{key}'\nGot error: '#{ActiveSupport::JSON.decode(@response.body)['errors'].map{|k,v| "#{k}=#{v}"}.join('&')}'" if (key.downcase == "ok" and value == "1" and json != value)

  json.should eql(value), assert_msg
end

Then %r/^the REST result "([^"]*)" contains "([^"]*)"$/ do |key, value|
  json = ActiveSupport::JSON.decode(@response.body)
  assert json[key].to_s =~ /#{value}/i, "Did not find \"#{value}\" in the message \"#{json[key].inspect}\""
end

def get_testsessionid(file)
  FileAttachment.where('file_file_name like ?', '%' + file).first.attachable_id
end

And %r/^session "([^"]*)" has been modified at "([^"]*)"$/ do |file, date|
  tid = get_testsessionid(file)
  d = DateTime.parse(date)
  ActiveRecord::Base.connection.execute("update meego_test_sessions set updated_at = '#{d}' where id = #{tid}")
end

And %r/^session "([^"]*)" has been tested at "([^"]*)"$/ do |file, date|
  tid = get_testsessionid(file)
  d = DateTime.parse(date)
  ActiveRecord::Base.connection.execute("update meego_test_sessions set tested_at = '#{d}' where id = #{tid}")
end

Then "result should match the file with defined date" do
  step %{resulting JSON should match file "short2.csv"}
end

Then "result should match the file with oldest date" do
  step %{resulting JSON should match file "short1.csv"}
end

# Validate the fields in response, this is used by QA Dashboard
Then "the result should contain all expected fields" do
  json = ActiveSupport::JSON.decode(@response.body)
  session_fields = ["qa_id", "title",
                    "release", "profile", "testset", "product",
                    "created_at", "updated_at", "tested_at", "weeknum",
                    "total_cases", "total_pass", "total_fail", "total_na", "total_measured"]
  feature_fields = ["qa_id", "name",
                    "total_cases", "total_pass", "total_fail", "total_na", "total_measured"]
  tc_fields      = ["qa_id", "name", "result", "bugs"]

  session_fields.each do |f|
    json[0].keys.should include(f)
  end

  json[0]['total_cases'].should == 2

  json[0]['features'].length.should == 2
  json[0]['features'][0]['testcases'].length.should == 1
  json[0]['features'][1]['testcases'].length.should == 1

  json[0]['features'].each do |feature|
    feature_fields.each do |f|
      feature.keys.should include(f)
    end

    feature['testcases'].each do |tc|
      tc_fields.each do |f|
        tc.keys.should include(f)
      end
    end
  end
end

Then %r/^resulting JSON should match file "([^"]*)"$/ do |file1|
  json = ActiveSupport::JSON.decode(@response.body)
  json[0]['qa_id'].should == get_testsessionid(file1)
  json.count.should == 1
end

Then %r/^I get a "([^"]*)" response code$/ do |code|
  @response.status.should == code.to_i
end

Given "three report files with variation in statuses and cases have been uploaded" do
  step %{the client sends file "features/resources/cumulative1.csv" via the REST API}
  step %{the client sends file "features/resources/cumulative2.csv" via the REST API}
  step %{the client sends file "features/resources/cumulative3.csv" via the REST API}
  # Update here, no need to have a step in the feature for this
  step %{session "cumulative1.csv" has been tested at "2011-01-01 01:01"}
  step %{session "cumulative2.csv" has been tested at "2011-02-01 01:01"}
  step %{session "cumulative3.csv" has been tested at "2011-03-01 01:01"}
end

Given "I set the default prefix for patches included CSV shortcut" do
  APP_CONFIG['patches_included_default_prefix'] = "GER"
end

Then "I remove the default prefix for patches included CSV shortcut" do
  APP_CONFIG['patches_included_default_prefix'] = ""
end

Given "I define a mapping for API parameters" do
  APP_CONFIG['api_mapping'] = {'release_version' => 'platform', 'target' => 'branch', 'testset' => 'team', 'product' => 'testtype'}
end

Then "I disable mapping of API parameters" do
  APP_CONFIG['api_mapping'] = {'release_version' => '', 'target' => '', 'testset' => '', 'product' => ''}
end

Then(/^all measurement groups and series are found$/) do
  SerialMeasurementGroup.all.count.should == 11
  SerialMeasurement.all.count.should == 20

  tc = MeegoTestCase.find_by_name("Grouped serial measurements - interval")
  sg = SerialMeasurementGroup.where(meego_test_case_id: tc)
  sg[0].name.should == "Load measurements"
  SerialMeasurement.where(serial_measurement_group_id: sg[0]).count.should == 2
end
