# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

class GemfilelintTest < Minitest::Test
  class OffenseLogger
    attr_reader :offenses

    def initialize
      @offenses = 0
    end

    def info(message)
      @offenses += 1 if message == "\e[35mW\e[0m"
    end
  end

  def test_version
    refute_nil ::Gemfilelint::VERSION
  end

  def test_violations
    assert_offenses(4, <<~GEMFILE)
      source 'https://rubgems.org'

      gem 'rail'
      gem 'rack-atack'
      gem 'rspc'
    GEMFILE
  end

  def test_clean
    assert_offenses(0, <<~GEMFILE)
      source 'https://rubygems.org'

      gem 'rails'
      gem 'rack-attack'
      gem 'rspec'
    GEMFILE
  end

  private

  def assert_offenses(offenses, content)
    logger = OffenseLogger.new

    with_gemfile(content) do |path|
      exit_code = offenses.positive? ? 1 : 0
      assert_equal exit_code, Gemfilelint.lint(path, logger: logger)
    end

    assert_equal offenses, logger.offenses
  end

  def with_gemfile(content)
    file = Tempfile.new(['Gemfile-', '.gemfile'])

    begin
      file.write(content)
      file.rewind

      yield file.path
    ensure
      file.close
      file.unlink
    end
  end
end
