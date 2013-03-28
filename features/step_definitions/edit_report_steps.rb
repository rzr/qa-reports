def find_testcase_row(tcname)
  namecell = page.find(".testcase_name", :text => tcname)
  namecell.find(:xpath, "ancestor::tr")
end

Given %r/^the report for "([^"]*)" exists on the service$/ do |file|
  step "I am a user with a REST authentication token"

  # @default_api_opts defined in features/support/hooks.rb
  response = api_import @default_api_opts_all.merge( "report.1" => Rack::Test::UploadedFile.new("features/resources/#{file}", "text/xml") )
  response.status.should == 200
end


When %r/^(?:|I )edit the report "([^"]*)"$/ do |report_string|
  version, target, test_type, product = report_string.downcase.split('/')
  report = MeegoTestSession.first(:conditions =>
   {"releases.name" => version, "profiles.name" => target, :product => product, :testset => test_type}, :include => [:release, :profile],
   :order => "tested_at DESC, created_at DESC")
  raise "report not found with parameters #{version}/#{target}/#{product}/#{test_type}!" unless report
  visit("/#{version}/#{target}/#{test_type}/#{product}/#{report.id}/edit")
end

And %r/^(?:|I )delete the test case "([^"]*)"/ do |testcase|
  tc = MeegoTestCase.find_by_name(testcase)
  with_scope("#testcase-#{tc.id}") do
    click_link "Remove"
  end
end

When %r/^(?:|I )click the element "([^"]*)" for the test case "([^"]*)"$/ do |element, test_case|
  find(:xpath, "//tr[contains(.,'#{test_case}')]").find(element).click
end

When %r/^(?:|I )delete all test cases/ do
  step %{I follow "See all"}

  session = MeegoTestSession.find(current_url.split('/')[-2])
  session.meego_test_cases.each do |tc|
    with_scope("#testcase-#{tc.id}") do
      click_link "Remove"
    end
  end
end

Then %r/^the report should not contain a detailed test results section/ do
  step %{I should not see "Detailed Test Results"}
end

When %r/^I change the test case result of "([^"]*)" to "([^"]*)"$/ do |tc, result|
  row = find_testcase_row(tc)
  row.find('.testcase_result').click()
  row.select(result, :from => "test_case[result_name]")
end

Then %r/^the result of test case "([^"]*)" should be "([^"]*)"$/ do |tc, result|
  actual = find_testcase_row(tc).find(".testcase_result .content")
  actual.should have_content(result), "Expected text case '#{tc}' result to be '#{result}'\nGot result '#{actual.text}'\n"
end

When %r/^I change the test case comment of "([^"]*)" to "([^"]*)"$/ do |tc, comment|
  row = find_testcase_row(tc)
  cell = row.find('.testcase_notes')
  cell.click()
  cell.fill_in "test_case[comment]", :with => comment
end

Then %r/^the result edit dropdown should not contain "([^"]*)"$/ do |result|
  opts = all(:xpath, "//select[@name='test_case[result_name]'][1]/option", :visible => false)
  # TODO there must be a far better way to do this. opts.should_not have_content(result) didn't work
  for elem in opts do
    assert_not_equal result, elem.value, "Expected option '#{elem.value}' not to exist"
  end
end

Given %r/^I enable custom results (".+")$/ do |results|
  results = results.scan(/"([^"]+?)"/).flatten

  APP_CONFIG['custom_results'] = results

  results.each do |result|
    FactoryGirl.create(:custom_result, :name => result)
  end
end

Then /^I disable custom results$/ do
  APP_CONFIG['custom_results'] = []
end

When /^I hide the report summary$/ do
  with_scope("#test_results") do
    click_link "Remove"
  end
end

When /^I enable the report summary$/ do
  step %{I hide the report summary}
end

When /^I hide the report metrics$/ do
  with_scope("#report_metrics") do
    click_link "Remove"
  end
end

Then /^I enable the report metrics$/ do
  step %{I hide the report metrics}
end

Given /^I enable inlining images$/ do
  APP_CONFIG['inline_images'] = true
end

Then /^I disable inlining images$/ do
  APP_CONFIG['inline_images'] = false
end

Given /^I add another Bugzilla service$/ do
  SERVICES << @mozilla_bugzilla
end

Then /^I remove the other Bugzilla service$/ do
  SERVICES.pop()
end

Then /^I should see link to bug "(.*?)" within "(.*?)"$/ do |id, selector|
  with_scope(selector) do
    page.should have_xpath("//a[contains(@href, '#{id}')]")
  end
end
