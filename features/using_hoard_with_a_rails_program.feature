Feature: Using Hoard With A Rails Program

  In order to speed up a slow-ass Rails application
  A rails developer
  Wants to create a directory of links to use as the load path

  Background:
    Given a Rails application "app"
    And we switch to the "app" directory
    And "rake db:migrate" is run
    And "require 'hoard/rails/tasks'" is added to the file "Rakefile"
    And the following is added to the file "config/environment.rb" after the line containing "'boot'":
      """
      require 'hoard'
      Hoard.init :rails
      """

  Scenario: Creating the hoard
    Given the "HOARD" environment variable is set
    When "rake hoard" is run
    Then "hoard/1/active_record.rb" should be a symlink

  Scenario: Using the hoard
    Given "rake hoard" is run
    When "script/runner 'puts $:'" is run
    Then the output should be:
      """
      ./hoard/1
      ./hoard/2
      """
    # 2nd layer is needed for binaries (rails, rake) as long as
    # Rubygems adds bin directories to load paths.

  Scenario: Running the program without creating the hoard
    When "script/runner 'puts $:'" is run
    Then the output should not contain "./hoard"
