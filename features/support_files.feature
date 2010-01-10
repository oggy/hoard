Feature: Support Files

  As a developer using a library which depends on files outside the lib directory
  I want to declare support files
  So I can not waste my life waiting for my application to load

  Background:
    Given a ruby program "program.rb" containing:
      """
      require 'hoard'
      Hoard.init 'config.yml', :creating => ENV['HOARD']

      $:.replace(['./lib'])
      Hoard.ready
      require 'mylib'
      puts Mylib::MESSAGE
      """
    And a file "config.yml" containing:
      """
      support_files:
        lib:
          mylib.rb:
            ../data/message
      """
    And a file "lib/mylib.rb" containing:
      """
      module Mylib
        path = File.dirname(__FILE__) + '/../data/message'
        MESSAGE = File.read(path)
      end
      """
    And a file "data/message" containing:
      """
      Message found.
      """
    And the "HOARD" environment variable is set
    And "ruby program.rb" is run
    When the "HOARD" environment variable is unset
    And "ruby program.rb" is run
    Then the output should be:
      """
      Message found.
      """
