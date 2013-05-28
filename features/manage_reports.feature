Feature: Manage reports

  Background:
    Given the report for "sample.csv" exists on the service
    And I am logged in
    When I view the report "1.2/Core/automated/N900"

  @smoke
  Scenario: Viewing a report
    And I should see the header

    And I should see "Check home screen"
    And I should see "Fail"
    And I should see "3921"

  @smoke
  Scenario: Printing a report
	  When I click to print the report

    And I should not see the header

    And I should see "Check home screen"
    And I should see "Fail"
    And I should see "3921"

  @smoke
  Scenario: Editing a report
    When I click to edit the report

    Then I should see "Edit the report information" within the first ".notification"
    And I should see "Test Objective" within ".editable_text #test_objective"

  Scenario: Linking from print view to report view
    When I click to print the report

    Then I should see "Click here to view this message in your browser or handheld device" within ".report-backlink"
    And the link "Click here" within ".report-backlink" should point to the report "1.2/Core/automated/N900"

  @selenium
  Scenario: Deleting a report
    When I view the report "1.2/Core/automated/N900"
    And I click to delete the report

    Then I should see "Are you sure you want to delete"

    When I click to confirm the delete

    Then I should be on the homepage
    And I should not be able to view the report "1.2/Core/automated/N900"

  @selenium
  Scenario: Deleting a report removes only expected data
    When I upload two NFT test reports
    And I upload two NFT test reports
    And I view the report "1.2/Handset/NFT/N900"
    And I click to delete the report
    When I click to confirm the delete

    Then I should find data for the other report from the database

  Scenario: Link to original result file is shown
    When I view the report "1.2/Core/automated/N900"

    And I should see the download link for the result file "sample.csv"