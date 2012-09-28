Feature: Test Report: Result Summary
In order to get high level over view of the test results,
As a QA Team Leader,
I want to see pass, fail and N/A totals. Additionally, I want to see run rate, pass rate and NFT index.

  Scenario: Result Summary for Functional Test Report
    Given I view a report with results: 5 Passed, 4 Failed, 2 N/A
    Then  I should see Result Summary:
      | Title                 | Result | [Explanation]                        |
      | Total test cases      |    11  |                                      |
      | Passed                |     5  |                                      |
      | Failed                |     4  |                                      |
      | N/A                   |     2  |                                      |
      | Run rate              |    82% | (Passed + Failed) / Total test cases |
      | Pass rate of total    |    45% | Passed / Total test cases            |
      | Pass rate of executed |    56% | Passed / (Total test cases - N/A)    |
    And I should not see in Result Summary:
      | Title                 |
      | Measured              |
      | NFT Index             |

 Scenario: Result Summary for NFT Test Report
    Given I view a report with results:
      | Result         | Value   | Target  | Fail_limit | [Explanation]                                 |
      | N/A            |         |   5 ms  |            | NFT Index:                             =   0% |
      | Measured       |   5 ms  |         |            | Doesn't affect to NFT Index                   |
      | Fail           |   7 ms  |   5 ms  |            | NFT Index: Target / Value              =  71% |
      | Fail           |  25 fps |  30 fps |            | NFT Index: Value  / Target             =  83% |
      | Pass           |  10 s   |   9 s   |   11 s     | NFT Index: Target / Value              =  90% |
      | Pass           |   8 s   |   9 s   |            | NFT Index: Min(100 %, Target / Value)  = 100% |

    Then  I should see Result Summary:
      | Title                 | Result | [Explanation]                                        |
      | Total test cases      |     6  |                                                      |
      | Passed                |     2  |                                                      |
      | Failed                |     2  |                                                      |
      | N/A                   |     1  |                                                      |
      | Measured              |     1  |                                                      |
      | Run rate              |    83% | (Total test cases - N/A) / Total test cases          |
      | Pass rate of total    |    40% | Passed / (Total test cases - Measured)               |
      | Pass rate of executed |    50% | Passed / (Total test cases - Measured - N/A)         |
      | NFT Index             |    69% | Sum(Test Case NFT Index) / Test Cases with NFT index |

  Scenario: Result summary for custom results
    Given I am logged in
    And I enable custom results "Pending", "Blocked"

    When I follow "Add report"
    And I select target "Handset", test set "Custom Results" and product "N990"
    And I attach the report "custom_statuses.xml"
    And I press "Next"
    And I press "Publish"

    Then I should see Result Summary:
      | Title                 | Result | [Explanation]                                        |
      | Total test cases      |     5  |                                                      |
      | Passed                |     1  |                                                      |
      | Failed                |     0  |                                                      |
      | N/A                   |     4  |                                                      |
      | Run rate              |    20% | (Total test cases - N/A) / Total test cases          |
      | Pass rate of total    |    20% | Passed / (Total test cases - Measured)               |
      | Pass rate of executed |   100% | Passed / (Total test cases - Measured - N/A)         |

  Scenario: Result summary as json
    Given the report for "results_by_feature.csv" exists on the service

    When I request the report summary as json

    Then I should get the summary for the whole report
    And I should get the summary for each feature

  Scenario: Result summary as JSON when custom results are enabled
    Given I am a user with a REST authentication token
    And I enable custom results "Pending", "Blocked"

    When the client sends file with custom results
    Then the upload succeeds

    When I request the report summary as json
    Then I see custom result counts in summary
    And I disable custom results

  Scenario: Cumulative result summary as JSON
    Given I am a user with a REST authentication token
    And three report files with variation in statuses and cases have been uploaded

    When I request a cumulative report over all reports under "1.2/Core/automated/N900" as JSON
    Then I should get the cumulative summary for the whole report
    And I should get the cumulative summary for each feature
