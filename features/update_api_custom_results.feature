Feature: Update API
  In order to provide a REST API for updating the result of test cases from a special report.
  The API respond at /api/update/<report_id>

  Background:
    Given I am a user with a REST authentication token

  Scenario: Updating test report with custom results by adding more cases to the report after having disabled custom results
    Given I see DB
    Given I enable custom results "Pending", "Blocked"
    When the client sends partial file with custom results
    Then the upload succeeds
    Then I see DB

    When I disable custom results
    And the client sends updated file with custom results
    Then the upload fails

    When I view the updated report
    Then I should see Result Summary:
      | Title                 | Result | [Explanation]                                        |
      | Total test cases      |     2  |                                                      |
      | Passed                |     1  |                                                      |
      | Failed                |     0  |                                                      |
      | N/A                   |     1  |                                                      |

  Scenario: Updating test report with custom results by adding more cases to the report
    Given I enable custom results "Pending", "Blocked"
    When the client sends partial file with custom results
    Then the upload succeeds

    And the client sends updated file with custom results
    Then the upload succeeds

    When I view the updated report
    Then I should see Result Summary:
      | Title                 | Result | [Explanation]                                        |
      | Total test cases      |     5  |                                                      |
      | Passed                |     1  |                                                      |
      | Failed                |     0  |                                                      |
      | N/A                   |     4  |                                                      |
