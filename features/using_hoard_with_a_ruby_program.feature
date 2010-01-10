Feature: Using hoard with a ruby program

  In order to speed up application load time
  A developer
  Wants to create a directory of links to use as the load path

  Background:
    Given an empty file "lib/mylib.rb"
    And a ruby program "program.rb" containing:
      """
      require 'hoard'
      Hoard.init(:creating => ENV['HOARD'])

      $:.replace(['./lib'])

      Hoard.ready

      puts 'program run'
      puts $:
      """

  Scenario: Creating the hoard
    Given the "HOARD" environment variable is set
    When "ruby program.rb" is run
    Then there should be no output
    And "hoard" should be a directory
    And "hoard/1/mylib.rb" should be a symlink to "lib/mylib.rb"

  Scenario: Using the hoard
    Given the "HOARD" environment variable is set
    And "ruby program.rb" is run
    And the "HOARD" environment variable is unset
    When "ruby program.rb" is run
    Then the output should be:
      """
      program run
      ./hoard/1
      """

  Scenario: Running the program without creating the hoard
    When "ruby program.rb" is run
    Then the output should contain:
      """
      program run
      """
    And "hoard" should not exist
