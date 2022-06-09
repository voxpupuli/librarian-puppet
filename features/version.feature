Feature: cli/version

  Scenario: Getting the version
    When I successfully run `librarian-puppet version`
    And the output should contain "librarian-"
