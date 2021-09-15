# frozen_string_literal: true

require "test_helper"
require "tempfile"

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
      source "https://rubgems.org"

      gem "rail"
      gem "rack-atack"
      gem "rspc"
    GEMFILE
  end

  def test_clean
    assert_offenses(0, <<~GEMFILE)
      source "https://rubygems.org"

      gem "rails"
      gem "rack-attack"
      gem "rspec"
    GEMFILE
  end

  def test_ignore
    assert_offenses(0, <<~GEMFILE, ignore: %w[rspc])
      source "https://rubygems.org"

      gem "rspc"
    GEMFILE
  end

  def test_multiple
    logger = OffenseLogger.new

    with_gemfile('gem "rail"') do |path1|
      with_gemfile('gem "rspc"') do |path2|
        refute Gemfilelint.lint(path1, path2, logger: logger)
      end
    end

    assert_equal 2, logger.offenses
  end

  def test_invocation
    response = false

    with_gemfile('gem "rail"; gem "rspc"') do |path|
      capture_subprocess_io do
        executable = File.expand_path("../exe/gemfilelint", __dir__)
        response = system("#{executable} --ignore rail,rspc #{path}")
      end
    end

    assert response
  end

  private

  def assert_offenses(offenses, content, ignore: [])
    logger = OffenseLogger.new

    with_gemfile(content) do |path|
      result = Gemfilelint.lint(path, ignore: ignore, logger: logger)
      assert_equal !offenses.positive?, result
    end

    assert_equal offenses, logger.offenses
  end

  def with_gemfile(content)
    file = Tempfile.new(["Gemfile-", ".gemfile"])

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
