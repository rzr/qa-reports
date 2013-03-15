Feature: Authentication
  In order to submit test reports to the system
  MeeGo test engineers
  Want to be able to log in to MeeGoQA

  Scenario: Log in with valid credentials
    Given I am not logged in
    And   I am viewing a test report
    When  I log in with valid credentials
    Then  I should be redirected back to the report I was viewing
    And   I should see my username and "Sign out" button

  Scenario: Log in with incorrect email
    Given I am not logged in
    When  I log in with incorrect email
    Then  I should see "Invalid email or password"

  Scenario: Log in with correct email but incorrect password
    Given I am not logged in
    When  I log in with incorrect password
    And   I should see "Invalid email or password"

  Scenario: Logging out
    Given I am logged in
    And   I am viewing a test report
    When  I log out
    Then  I should be on the front page
    And   I should see "Sign In"
