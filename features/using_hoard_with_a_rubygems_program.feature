Feature: Using hoard with a rubygems program

  In order to speed up the load time of a rubygems application
  A developer
  Wants to create a directory of links to use as the load path

  Background:
    Given a gem "hoard-test-gem-one" containing the following files:
      | path                        | content                        |
      | lib/hoard-test-gem-one.rb   | require 'hoard-test-gem-one/a' |
      | lib/hoard-test-gem-one/a.rb | A = 1                          |
    And gem "hoard-test-gem-one" has a require path "lib"

    And a gem "hoard-test-gem-two" containing the following files:
      | path                        | content                              |
      | bin/hoard-test-gem-two      | require 'hoard-test-gem-two'; puts B |
      | lib/hoard-test-gem-two.rb   | require 'hoard-test-gem-two/a'       |
      | lib/hoard-test-gem-two/a.rb | B = 2                                |
      | data/file                   | .                                    |
    And gem "hoard-test-gem-two" has a require path "lib"
    And gem "hoard-test-gem-two" has a require path "bin"

    And a ruby program "program.rb" containing:
      """
      require 'rubygems'
      Gem.use_paths('home', ['gem_repo'])

      require 'hoard'
      Hoard.init('hoard.yml', :create => ENV['HOARD'])

      require 'hoard-test-gem-one'
      require 'hoard-test-gem-two'

      Hoard.ready

      puts 'program run'
      puts $:
      """
    And a file "hoard.yml" containing:
      """
        type: rubygems
        gem_support_files:
          hoard-test-gem-two:
            bin:
              hoard-test-gem-two: ../data/file
      """

  Scenario: Creating the hoard
    Given the "HOARD" environment variable is set
    When "ruby program.rb" is run
    Then there should be no output
    And "hoard" should be a directory
    And "hoard/1/hoard-test-gem-one" should be a symlink to "lib/hoard-test-gem-one" in gem "hoard-test-gem-one"
    And "hoard/1/hoard-test-gem-one.rb" should be a symlink to "lib/hoard-test-gem-one.rb" in gem "hoard-test-gem-one"
    And "hoard/1/hoard-test-gem-two" should be a symlink to "lib/hoard-test-gem-two" in gem "hoard-test-gem-two"
    And "hoard/1/hoard-test-gem-two.rb" should be a symlink to "lib/hoard-test-gem-two.rb" in gem "hoard-test-gem-two"
    And "hoard/2/__hoard__/hoard-test-gem-two" should be a symlink to "bin/hoard-test-gem-two" in gem "hoard-test-gem-two"
    And "hoard/2/data/file" should be a symlink to "data/file" in gem "hoard-test-gem-two"

  Scenario: Using the hoard
    Given the "HOARD" environment variable is set
    And "ruby program.rb" is run
    And the "HOARD" environment variable is unset
    When "ruby program.rb" is run
    Then the output should be:
      """
      program run
      ./hoard/1
      ./hoard/2/__hoard__
      """

  Scenario: Running the program without creating the hoard
    When "ruby program.rb" is run
    Then the output should contain:
      """
      program run
      """
    And "hoard" should not exist
