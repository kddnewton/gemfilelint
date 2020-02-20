require 'test_helper'
require 'tempfile'

class GemlintTest < Minitest::Test
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
    refute_nil ::Gemlint::VERSION
  end

  def test_violations
    content = <<~GEMFILE
      source 'https://rubgems.org'

      gem 'rail'
      gem 'rack-atack'
      gem 'rspc'
    GEMFILE

    logger = OffenseLogger.new

    with_gemfile(content) do |path|
      assert_equal 1, Gemlint.lint(path, logger: logger)
    end

    assert_equal 4, logger.offenses
  end

  def test_clean
    content = <<~GEMFILE
      source 'https://rubygems.org'

      gem 'rails'
      gem 'rack-attack'
      gem 'rspec'
    GEMFILE

    logger = OffenseLogger.new

    with_gemfile(content) do |path|
      assert_equal 0, Gemlint.lint(path, logger: logger)
    end

    assert_equal 0, logger.offenses
  end

  private

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
