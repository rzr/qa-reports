Feature: Edit Report

  Background:
    Given the report for "short-sim.csv" exists on the service
    And I am logged in

  @javascript
  Scenario: Add and view a test case attachment for existing report
    When I edit the report "1.2/Core/automated/N900"

    When I click the element ".testcase_notes" for the test case "SMOKE-SIM-Get_IMSI"
    And I attach the file "attachment.txt" to test case "SMOKE-SIM-Get_IMSI"
    And I wait until all Ajax requests are complete

    When I click the element ".testcase_notes" for the test case "SMOKE-SIM-Get_IMSI"
    And I click the element ".attachment_link" for the test case "SMOKE-SIM-Get_IMSI"

    Then I should see "Content of the attachment file"

  @javascript
  Scenario: Add and remove a test case attachment from existing report
    When I edit the report "1.2/Core/automated/N900"

    When I click the element ".testcase_notes" for the test case "SMOKE-SIM-Get_IMSI"
    And I attach the file "short1.csv" to test case "SMOKE-SIM-Get_IMSI"
    And I wait until all Ajax requests are complete

    Then I click the element ".testcase_notes" for the test case "SMOKE-SIM-Get_IMSI"
    And I should see "short1.csv"

    When I remove the attachment from the test case "SMOKE-SIM-Get_IMSI"
    And I wait until all Ajax requests are complete

    When I click the element ".testcase_notes" for the test case "SMOKE-SIM-Get_IMSI"
    Then I should not see "short1.csv"

  @javascript
  Scenario: Edit title
    When I edit the report "1.2/Core/automated/N900"
    And I click the element "h1"
    And fill in "report[title]" with "Test title" within "h1"
    And I press "Save"
    And I wait until all Ajax requests are complete

    Then I should see "Test title" within "h1"

  @javascript
  Scenario: Edit test execution date
    When I view the report "1.2/Core/automated/N900"
    And I click to edit the report
    And I click the element ".editable_date"
    And fill in "Test execution date:" with "2011-1-1"
    And I press "Save"

    Then I should see "01 January 2011" within "#test_category .date"

  @javascript
  Scenario: Edit test objective
    When I edit the report "1.2/Core/automated/N900"
    And I click the element "#test_objective"
    And fill in "report[objective_txt]" with:
      """
      == Test Header ==
      * testing list
      """
    And I press "Save"

    Then I should see "testing list" within ".editable_area ul li"
    And I should see "Test Header" within ".editable_area h3"

  @javascript
  Scenario: Create a dynamic link to bugzilla
    When I edit the report "1.2/Core/automated/N900"
    And I click the element "#test_objective"
    And fill in "report[objective_txt]" with "* [[9353]]"
    And I press "Save"

    Then I should see link to bug "9353" within ".editable_area ul li"

  @javascript
  Scenario: Create a dynamic link to bugzilla using a prefix
    When I edit the report "1.2/Core/automated/N900"
    And I click the element "#test_objective"
    And fill in "report[objective_txt]" with "* [[BZ#9353]]"
    And I press "Save"

    Then I should see link to bug "9353" within ".editable_area ul li"

  @javascript
  Scenario: Create dynamic links to two bugzilla servers
    Given I add another Bugzilla service
    When I edit the report "1.2/Core/automated/N900"
    And I click the element "#test_objective"
    And fill in "report[objective_txt]" with "* [[BZ#9353]] [[MOZ#1234]] [[1234]]"
    And I press "Save"

    Then I should see link to bug "https://bugs.merproject.org/show_bug.cgi?id=9353" within ".editable_area ul li"
    And I should see link to bug "https://bugs.merproject.org/show_bug.cgi?id=1234" within ".editable_area ul li"
    And I should see link to bug "https://bugzilla.mozilla.org/show_bug.cgi?id=1234" within ".editable_area ul li"
    And I remove the other Bugzilla service

  @javascript
  Scenario: Convert links to two bugzilla servers
    Given I add another Bugzilla service
    When I edit the report "1.2/Core/automated/N900"
    And I click the element "#test_objective"
    And fill in "report[objective_txt]" with "* https://bugs.merproject.org/show_bug.cgi?id=9353 https://bugzilla.mozilla.org/show_bug.cgi?id=1234"
    And I press "Save"

    Then I should see link to bug "https://bugs.merproject.org/show_bug.cgi?id=9353" within ".editable_area ul li"
    And I should see link to bug "https://bugzilla.mozilla.org/show_bug.cgi?id=1234" within ".editable_area ul li"
    And I remove the other Bugzilla service

  @javascript
  Scenario: Markup help shows syntax for all external services
    Given I add another Bugzilla service
    When I edit the report "1.2/Core/automated/N900"
    And I click the element "#test_objective"
    Then I should see markup help for both Bugzilla service
    And I remove the other Bugzilla service

  @javascript
  Scenario: Create dynamic link to an external link only service
    Given I add a link only external service
    When I edit the report "1.2/Core/automated/N900"
    And I click the element "#test_objective"
    And fill in "report[objective_txt]" with "* [[GER#9353]]"
    And I press "Save"

    Then I should see link to bug "http://review.cyanogenmod.org/#/c/9353/" within ".editable_area ul li"
    And I remove the link only external service

  @javascript
  Scenario: Convert link to an external link only service
    Given I add a link only external service
    When I edit the report "1.2/Core/automated/N900"
    And I click the element "#test_objective"
    And fill in "report[objective_txt]" with "* http://review.cyanogenmod.org/#/c/9353/"
    And I press "Save"

    Then I should see link to bug "http://review.cyanogenmod.org/#/c/9353/" within ".editable_area ul li"
    And I remove the link only external service

  @javascript
  Scenario: I delete a test case
    When I edit the report "1.2/Core/automated/N900"
    And I delete the test case "SMOKE-SIM-Get_IMSI"

    Then I return to view the report "1.2/Core/automated/N900"
    And there should not be a test case "SMOKE-SIM-Get_IMSI"

  @javascript
  Scenario: I delete all test cases
    When I edit the report "1.2/Core/automated/N900"
    And delete all test cases

    Then I return to view the report "1.2/Core/automated/N900"
    Then the report should not contain a detailed test results section

  @javascript
  Scenario: I modify a test case result
    When I edit the report "1.2/Core/automated/N900"
    And I change the test case result of "SMOKE-SIM-Get_IMSI" to "Pass"
    And I follow the first "Done"
    And I follow "See all" within "#detailed_functional_test_results"

    Then the result of test case "SMOKE-SIM-Get_IMSI" should be "Pass"

  @javascript
  Scenario: I modify test case result with custom results enabled
    Given I enable custom results "Not tested", "Blocked"

    And I edit the report "1.2/Core/automated/N900"
    And I change the test case result of "SMOKE-SIM-Get_IMSI" to "Blocked"
    And I follow the first "Done"

    Then the result of test case "SMOKE-SIM-Get_IMSI" should be "Blocked"
    And I disable custom results

  @javascript
  Scenario: I modify test case with deprecated result with custom results enabled
    Given I enable custom results "Not tested", "Blocked"

    And I edit the report "1.2/Core/automated/N900"
    And I change the test case result of "SMOKE-SIM-Get_IMSI" to "Blocked"
    And I follow the first "Done"

    Then the result of test case "SMOKE-SIM-Get_IMSI" should be "Blocked"

    Then I enable custom results "Not tested"
    And I edit the report "1.2/Core/automated/N900"

    Then the result edit dropdown should not contain "Blocked"
    And I disable custom results

  @javascript
  Scenario: I modify a NFT test case result
    When I edit the report "1.2/Core/automated/N900"
    And I change the test case result of "Phone Connection time" to "Pass"
    And I follow the first "Done"
    And I follow "See all"

    Then the result of test case "Phone Connection time" should be "Pass"

  @selenium
  Scenario: I modify a test case comment
    When I edit the report "1.2/Core/automated/N900"
    And I change the test case comment of "SMOKE-SIM-Get_IMSI" to "edited comment"
    And I press "Save"
    And I follow the first "Done"

    Then I should see "edited comment"

  @javascript
  Scenario: I hide and reshow report summary
    When I edit the report "1.2/Core/automated/N900"

    And I hide the report summary
    And I follow the first "Done"

    Then I return to view the report "1.2/Core/automated/N900"
    And I should not see "Result Summary"

    Then I edit the report "1.2/Core/automated/N900"
    And I enable the report summary
    And I follow the first "Done"

    Then I return to view the report "1.2/Core/automated/N900"
    And I should see "Result Summary"

  @javascript
  Scenario: I hide and reshow report metrics
    Given the report for "xml_with_metrics.xml" exists on the service
    When I edit the report "1.2/Core/automated/N900" with largest ID

    And I hide the report metrics
    And I follow the first "Done"

    Then I return to view the report "1.2/Core/automated/N900"
    And I should not see "Metrics"

    Then I edit the report "1.2/Core/automated/N900" with largest ID
    And I enable the report metrics
    And I follow the first "Done"

    Then I return to view the report "1.2/Core/automated/N900"
    And I should see "Metrics"
