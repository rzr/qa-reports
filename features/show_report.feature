Feature: View report

  Scenario: View report as JSON
    Given the report for "results_by_feature.csv" exists on the service

    When I request the report details as JSON
    Then I should get the summary for the whole report
    And I should get the summary for each feature

    And I should get the test cases for each feature
