Feature:
  As a MeeGo QA Reports developer
  I want to ensure that all the landing pages have appropriate headers
  So that I know that at least the very basic stuff works

  @javascript
  Scenario: Visiting the front page

    When I go to the front page
    Then I should see "MeeGo" within "#logo"
    And I should see the sign in link without ability to add report
    And I should see the main navigation columns

  @javascript
  Scenario: Visiting the front page with custom app name
    Given I set application name to "My Custom Reports"

    When I go to the front page
    Then I should see "My Custom Reports" within "#logo"
    And I set application name to "MeeGo QA Reports"

  # http://stackoverflow.com/questions/8461755/capybara-how-to-test-a-stylesheet-of-a-page
  @wip @javascript
  Scenario: Visiting the front page with custom CSS in use
    Given I set custom CSS file "/stylesheets/themes/nokia.css"

    When I go to the front page
    Then the page should include CSS file "/stylesheets/themes/nokia.css"
    And I set custom CSS file ""

  @javascript
  Scenario: Disabling and enabling header navigation links
    Given I go to the front page
    And I should see "Give Feedback" within "#upper_header"
    And I should see "Documentation" within "#upper_header"
    And I should see "Submit an Idea" within "#upper_header"

    Then I disable all header links
    And I should not see "Give Feedback" within "#upper_header"
    And I should not see "Documentation" within "#upper_header"
    And I should not see "Submit an Idea" within "#upper_header"

    And I enable all header links
