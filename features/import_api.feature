Feature: Import API
  As an external service
  I want to upload reports via REST API
  So that they can be browsed by users

  Background:
    Given I am a user with a REST authentication token

  Scenario: Uploading a test report with single basic file
    When the client sends a basic test result file
    Then the upload succeeds
    And I should be able to view the created report

  Scenario: Uploading a test report with multiple files and attachments
    When the client sends files with attachments
    Then the upload succeeds
    And I should be able to view the created report

    Then I should see names of the two features
    And I should see the uploaded attachments

  Scenario: Uploading a test report with image attachments and inlining enabled
    Given I enable inlining images
    When the client sends files with attachments
    Then the upload succeeds
    And I should be able to view the created report

    Then I should see the two attached images
    And I disable inlining images

  Scenario: Uploading a test report with single basic file using deprecated API
    When the client sends a basic test result file via deprecated API
    Then the upload succeeds
    And I should be able to view the created report

  Scenario: Adding a report with deprecated parameters
    When the client sends a basic test result file with deprecated parameters
    Then the upload succeeds
    And I should be able to view the created report

  Scenario: Adding a report with deprecated product parameter
    When the client sends a basic test result file with deprecated product parameter
    Then the upload succeeds
    And I should be able to view the created report

  Scenario: Sending a report with string values instead of files
    When the client sends a request with string value instead of a file
    Then the upload fails
    And the result complains about invalid file

  Scenario: Sending a report without a valid report file
    When the client sends a request without file
    Then the upload fails
    And the result complains about missing file

  Scenario: Sending a report without a target profile
    When the client sends a request without a target profile
    Then the upload fails
    And the result complains about missing target profile

  Scenario: Sending a report with invalid release version
    When the client sends a request with invalid release version
    Then the upload fails
    And the result complains about invalid release version

  Scenario: Sending a report with invalid target profile
    When the client sends a request with invalid target profile
    Then the upload fails
    And the result complains about invalid target profile

  Scenario: Sending a report with product with not allowed characters
    When the client sends a request with invalid product
    Then the upload fails
    And the result complains about invalid product

  # Tests for additional parameters

  Scenario: Sending a report with invalid extra parameters
    When the client sends a request containing invalid extra parameter
    Then the upload fails
    And the result complains about invalid parameter

  Scenario: Sending a report with a user defined report title
    When the client sends a request with a defined title
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined report title

  Scenario: Sending a report with user defined test objective
    When the client sends a request with defined test objective
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined test objective

  Scenario: Sending a report with user defined build information
    When the client sends a request with defined build information
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined build information

  Scenario: Sending a report with user defined build ID
    When the client sends a request with defined build ID
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined build ID

  Scenario: Sending a report with user defined environment information
    When the client sends a request with defined environment information
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined environment information

  Scenario: Sending a report with user defined quality summary
    When the client sends a request with defined quality summary
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined quality summary

  Scenario: Sending a report with user defined issue summary
    When the client sends a request with defined issue summary
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined issue summary

  Scenario: Sending a report with all possible parameters
    When the client sends a request with all optional parameters defined
    Then the upload succeeds
    And I should be able to view the created report

    And I should see the defined report title
    And I should see the defined test objective
    And I should see the defined build ID
    And I should see the defined environment information
    And I should see the defined quality summary
    And I should see the defined issue summary
    And I should see the defined patches included

  Scenario: Sending a report using the CSV shortcut
    When the client sends a request CSV parameters for issues summary and patches included
    Then the upload succeeds
    And I should be able to view the created report

    And I should see a list of issues in issue summary
    And I should see a list of patches in patches included

  # Tests for additional parameters end

  Scenario: Test objective is copied from previous report if not given
    Given the client has sent a request with a defined test objective
    When the client sends a basic test result file

    Then the upload succeeds
    And I should be able to view the latest created report
    And I should see the objective of previous report

  Scenario: Getting a list of sessions from API
    When the client sends three CSV files
    And I download a list of sessions with begin time given
    Then result should match the file with defined date

  Scenario: Getting a list of sessions from API without date
    When the client sends three CSV files
    And I download a list of sessions without a begin time
    Then result should match the file with oldest date

  Scenario: Sending custom results when not enabled
    When the client sends file with custom results
    Then the upload fails
    And the result complains about invalid custom result

  Scenario: Sending custom results when enabled
    Given I enable custom results "Pending", "Blocked"
    When the client sends file with custom results

    Then the upload succeeds
    And I should be able to view the created report
    And I should see test cases with result Blocked
    And I disable custom results

  Scenario: Sending Google Test Framework result file
    When the client sends googletest result file
    Then the upload succeeds

    And I should be able to view the created report
    And I should see the defined test cases

  Scenario: Sending xUnit result file
    When the client sends xUnit result file
    Then the upload succeeds

    And I should be able to view the created report

    Then I press "See all"
    And I should see the test cases from xUnit result file

  Scenario: Sending results using custom API parameters
    Given I define a mapping for API parameters

    When the client sends a basic test result file via custom mapped API
    Then the upload succeeds
    And I should be able to view the created report

    And I disable mapping of API parameters

  Scenario: Sending results using default API parameters with custom parmeters enabled
    Given I define a mapping for API parameters

    When the client sends a basic test result file
    Then the upload succeeds
    And I should be able to view the created report

    And I disable mapping of API parameters

  Scenario: Sending result file with metrics
    When the client sends result file with metrics
    Then the upload succeeds

    And I should be able to view the created report

    And I should see "Reliability Summary"
    And I should see "Load Summary"
    And I should see "Average CPU load"
    And I should see "Response time under load"

  Scenario: Create a dynamic link to bugzilla
    When the client sends file with a bug ID in issue summary
    Then the upload succeeds
    And I should be able to view the created report
    And I should see a link to Bugzilla

  Scenario: Create a dynamic link to bugzilla using a prefix
    When the client sends file with a bug ID with prefix in issue summary
    Then the upload succeeds
    And I should be able to view the created report
    And I should see a link to Bugzilla

  Scenario: Create dynamic links to two bugzilla servers
    Given I add another Bugzilla service
    When the client sends file with bugs to two services in issue summary
    Then the upload succeeds
    And I should be able to view the created report
    And I should see a link to Bugzilla
    And I should see a link to Mozilla Bugzilla
    And I remove the other Bugzilla service

  Scenario: Convert links to two bugzilla servers
    Given I add another Bugzilla service
    When the client sends file with URIs to bugs in two services in issue summary
    Then the upload succeeds
    And I should be able to view the created report
    And I should see a link to Bugzilla
    And I should see a link to Mozilla Bugzilla
    And I remove the other Bugzilla service

  Scenario: Create dynamic link to an external link only service
    Given I add a link only external service
    When the client sends file patch ID in issue summary
    Then the upload succeeds
    And I should be able to view the created report
    And I should see a link to Gerrit
    And I remove the link only external service

  Scenario: Convert link to an external link only service
    Given I add a link only external service
    When the client sends file with URI to Gerrit patch in issue summary
    Then the upload succeeds
    And I should be able to view the created report
    And I should see a link to Gerrit
    And I remove the link only external service
