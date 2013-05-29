Feature: View several reports under a category

  Background:
    Given there are 2 reports from "2011/1" under "1.2/Core/Automated/N900"
    And there are 4 reports from "2011/3" under "1.2/Core/Automated/N900"

  @javascript
  Scenario: Viewing list of reports by month
    When I view the report category "1.2/Core/Automated/N900"
    Then reports from "2011/1" should be in the report list under "January 2011"
    And reports from "2011/3" should be in the report list under "March 2011"

  # TODO: Scrolling seems to launch an ajax request and we seem to wait for
  # them to complete but no new content appears on the body using capybara 2.1.
  # TODO: Fix this somehow
  @wip @javascript
  Scenario: More reports are loaded as the page is scrolled down
    Given there are 40 reports from "2011/4" under "1.2/Core/Automated/N900"

    When I view the report category "1.2/Core/Automated/N900"
    Then reports for "January 2011" should not be visible on the page

    Then I scroll down the page
    And reports from "2011/1" should be in the report list under "January 2011"

  @javascript
  Scenario: View the graph for recent report history
    When I view the report category "1.2/Core/Automated/N900"
    Then I should see a graph containing data for the most recent reports

  Scenario: Request the list of reports for a given category as json
    When I view the json for category "1.2/Core/Automated/N900"
    Then I should see a list of all reports under "1.2/Core/Automated/N900" as json
