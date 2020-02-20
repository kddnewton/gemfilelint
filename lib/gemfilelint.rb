# frozen_string_literal: true

require 'logger'

require 'bundler'
require 'bundler/similarity_detector'

require 'gemfilelint/version'

module Gemfilelint
  module Offenses
    class Dependency < Struct.new(:name, :suggestions)
      def to_s
        <<~ERR
          Gem \"#{name}\" is possibly misspelled, suggestions:
          #{suggestions.map { |suggestion| "   * #{suggestion}" }.join("\n")}"
        ERR
      end
    end

    class Remote < Struct.new(:name, :suggestions)
      def to_s
        <<~ERR
          Source \"#{name}\" is possibly misspelled, suggestions:
          #{suggestions.map { |suggestion| "   * #{suggestion}" }.join("\n")}
        ERR
      end
    end
  end

  class Linter
    class SpellChecker
      attr_reader :detector, :haystack

      def initialize(haystack)
        @detector = Bundler::SimilarityDetector.new(haystack)
        @haystack = haystack
      end

      def correct(needle)
        return [] if haystack.include?(needle)

        detector.similar_words(needle)
      end
    end

    module ANSIColor
      CODES = { green: 32, magenta: 35 }.freeze

      refine String do
        def colorize(code)
          "\033[#{CODES[code]}m#{self}\033[0m"
        end
      end
    end

    using ANSIColor

    attr_reader :dependency_checker, :remote_checker, :logger

    def initialize
      common_gems = File.read(File.expand_path('gems.txt', __dir__)).split("\n")

      @dependency_checker = SpellChecker.new(common_gems)
      @remote_checker = SpellChecker.new(['https://rubygems.org/'])
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def lint(*paths, logger: nil)
      logger ||= make_logger
      offenses = []

      paths.each do |path|
        logger.info("Inspecting gemfile at #{path}\n")

        each_offense_for(path) do |offense|
          if offense
            offenses << offense
            logger.info('W'.colorize(:magenta))
          else
            logger.info('.'.colorize(:green))
          end
        end

        logger.info("\n")
      end

      if offenses.empty?
        0
      else
        prefix = 'W'.colorize(:magenta)
        messages = offenses.map { |offense| "#{prefix}: #{offense}\n" }
        logger.info("\nOffenses:\n\n#{messages.join}\n")
        1
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    def make_logger
      Logger.new(STDOUT).tap do |logger|
        logger.level = :info
        logger.formatter = ->(*, message) { message }
      end
    end

    def each_offense_for(path)
      dsl = Bundler::Dsl.new
      dsl.eval_gemfile(path)

      # Lol wut, there has got to be a better way to do this
      source_list = dsl.instance_variable_get(:@sources)
      rubygems = source_list.instance_variable_get(:@rubygems_aggregate)

      dsl.dependencies.each do |dependency|
        yield dependency_offense_for(dependency.name)
      end

      rubygems.remotes.each do |remote|
        yield remote_offense_for(remote.to_s)
      end
    end

    def dependency_offense_for(name)
      corrections = dependency_checker.correct(name)
      Offenses::Dependency.new(name, corrections.first(5)) if corrections.any?
    end

    def remote_offense_for(uri)
      corrections = remote_checker.correct(uri)
      Offenses::Remote.new(uri, corrections) if corrections.any?
    end
  end

  def self.lint(*paths, logger: nil)
    Linter.new.lint(*paths, logger: logger)
  end
end
