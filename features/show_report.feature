Feature: View report

  Scenario: View report as JSON
    Given the report for "results_by_feature.csv" exists on the service

    When I request the report details as JSON
    Then I should get the summary for the whole report
    And I should get the summary for each feature

    And I should get the test cases for each feature

  @wip
  Scenario: View cumulative report as JSON
    Given I am a user with a REST authentication token
    And three report files with variation in statuses and cases have been uploaded

    When I request a cumulative report over all reports under "1.2/Core/automated/N900" as JSON
    Then I should get the cumulative summary for the whole report
    And I should get the cumulative summary for each feature

    And I should get the cumulative test cases for each feature
