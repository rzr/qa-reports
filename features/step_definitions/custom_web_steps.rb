Then %r/^(?:|I )should see "([^\"]*)" within the first "([^\"]*)"$/ do |text, selector|
  first(selector).should have_content(text)
end

Then %r/^show me the response$/ do
  puts page.body.inspect
end

When /submit the form(?: at "([^"]*)")?$/ do |form_id|
  target = form_id ? "#"+form_id : "input[@type='submit']"
  find(target).click
end

When /submit the form at "([^"]*)" within "([^"]*)"?$/ do |submit_button, selector|
  with_scope(selector) do
    find(submit_button).click
  end
end

When %r/^(?:|I )wait until all Ajax requests are complete$/ do
  while page.evaluate_script('$.active') != 0
    sleep 0.5
  end
end

When %r/^I wait for (\d+)s$/ do |n|
  sleep n.to_i
end

Then %r/^I should really see "([^\"]*)"(?: within "([^\"]*)")?$/ do |text, locator| #"
  if Capybara.current_driver == :selenium or Capybara.current_driver == :webkit
    script = <<-eos
    (function () {
      var containsText = $('#{locator} :contains(#{text}), #{locator}:contains(#{text})');
      var leaves = containsText.not(containsText.parents()).filter(':visible');
      return leaves.filter(function() {return !$(this).parents().is(':hidden');}).length > 0;
    })();
    eos
    while page.evaluate_script(script) == false
      sleep 0.5
    end
  else
    with_scope(locator) do
      page.should have_content(text)
    end
  end
end

Then %r/^I really should not see "([^\"]*)"(?: within "([^\"]*)")?$/ do |text, locator| #"
  if Capybara.current_driver == :selenium or Capybara.current_driver == :webkit
    script = <<-eos
    (function () {
      var containsText = $('#{locator} :contains(#{text}), #{locator}:contains(#{text})');
      var leaves = containsText.not(containsText.parents()).filter(':visible');
      return leaves.filter(function() {return !$(this).parents().is(':hidden');}).length > 0;
    })();
    eos
    while page.evaluate_script(script) == true
      sleep 0.5
    end
  else
    with_scope(locator) do
      page.should have_no_content(text)
    end
  end
end


Then %r/^the link "([^"]*)" within "([^"]*)" should point to the report "([^"]*)"/ do |link, selector, expected_report|
  with_scope(selector) do
    field = find_link(link)

    version, target, testset, product = expected_report.split('/')
    report = MeegoTestSession.first(:conditions =>
     {"releases.name" => version, "profiles.name" => target, :product => product, :testset => testset}, :include => [:release, :profile]
    )
    raise "report not found with parameters #{version}/#{target}/#{hardware}/#{testset}!" unless report

    field[:href].should == "/#{version}/#{target}/#{testset}/#{product}/#{report.id}"
  end
end

When %r/^I click the element "([^"]*)"$/ do |selector|
  find(selector).click
end

When %r/^I scroll down the page$/ do
  page.evaluate_script('window.location.hash="footer";')
  step %{I wait until all Ajax requests are complete}
end

When %r/^I click the element "([^"]*)" within "([^"]*)"$/ do |element, selector|
  with_scope(selector) do
    find(element).click
  end
end

When %r/^fill in "([^"]*)" within "([^"]*)" with:$/ do |field, selector, data|
  with_scope(selector) do
    fill_in(field, :with => data)
  end
end

When %r/^I view the page for the release version "([^"]*)"$/ do |version|
  visit("/#{version}")
end

When %r/^I view the page for the "([^"]*)" (?:target|profile) of release version "([^"]*)"$/ do |target, version|
  visit("/#{version}/#{target}")
end

When %r/^I view the page for "([^"]*)" (?:|testing) of (?:target|profile) "([^"]*)" in version "([^"]*)"$/ do |test_type, target, version|
  visit("/#{version}/#{target}/#{test_type}")
end

When %r/^I view the page for "([^"]*)" (?:|testing )of "([^"]*)" hardware with (?:target|profile) "([^"]*)" in version "([^"]*)"$/ do |test_type, hardware, target, version|
  visit("/#{version}/#{target}/#{test_type}/#{hardware}")
end

Then %r/^(?:|I )should find element "([^"]*)"(?: within "([^"]*)")?$/ do |text, selector|
  with_scope(selector) do
    if page.respond_to? :should
      page.should have_selector(text)
    else
      assert page.has_selector?(text)
    end
  end
end

Then %r/^(?:|I )should not find element "([^"]*)"(?: within "([^"]*)")?$/ do |text, selector|
  with_scope(selector) do
    if page.respond_to? :should
      page.should have_no_selector(text)
    else
      assert page.has_no_selector?(text)
    end
  end
end

When %r/^(?:|I )follow the first "([^"]*)"$/ do |link|
  page.should have_content link
  first(:link, link).click
end
