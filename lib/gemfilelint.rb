# frozen_string_literal: true

require "logger"
require "bundler"
require "bundler/similarity_detector"
require "gemfilelint/version"

module Gemfilelint
  class SpellChecker
    attr_reader :detector, :haystack

    def initialize(haystack)
      @detector = Bundler::SimilarityDetector.new(haystack)
      @haystack = haystack
    end

    def correct(needle)
      return [] if haystack.include?(needle)

      detector.similar_words(needle, 2)
    end
  end

  module Offenses
    class Dependency < Struct.new(:path, :name, :suggestions)
      def to_s
        <<~ERR
          Gem "#{name}" is possibly misspelled, suggestions:
          #{suggestions.map { |suggestion| "   * #{suggestion}" }.join("\n")}"
        ERR
      end
    end

    class InvalidGemfile < Struct.new(:path)
      def to_s
        "Gemfile at \"#{path}\" is invalid."
      end
    end

    class Remote < Struct.new(:path, :name, :suggestions)
      def to_s
        <<~ERR
          Source "#{name}" is possibly misspelled, suggestions:
          #{suggestions.map { |suggestion| "   * #{suggestion}" }.join("\n")}
        ERR
      end
    end
  end

  module Parser
    class Valid < Struct.new(:path, :dsl)
      def each_offense(ignore: [])
        dependencies.each do |name|
          next if ignore.include?(name)

          if (corrections = Gemfilelint.dependencies.correct(name)).any?
            yield Offenses::Dependency.new(path, name, corrections.first(5))
          else
            yield nil
          end
        end

        remotes.each do |uri|
          if (corrections = Gemfilelint.remotes.correct(uri)).any?
            yield Offenses::Remote.new(path, uri, corrections)
          else
            yield nil
          end
        end
      end

      private

      def dependencies
        dsl.dependencies.map(&:name)
      end

      # Lol wut, there has got to be a better way to do this
      def remotes
        sources = dsl.instance_variable_get(:@sources)
        rubygems =
          sources.instance_variable_get(:@rubygems_aggregate) ||
            sources.instance_variable_get(:@global_rubygems_source)

        rubygems ? rubygems.remotes.map(&:to_s) : []
      end
    end

    class Invalid < Struct.new(:path)
      def each_offense(**)
        yield Offenses::InvalidGemfile.new(path)
      end
    end

    def self.for(path)
      Valid.new(path, Bundler::Dsl.new.tap { |dsl| dsl.eval_gemfile(path) })
    rescue Bundler::Dsl::DSLError
      Invalid.new(path)
    end
  end

  class Linter
    module ANSIColor
      CODES = { green: 32, magenta: 35, cyan: 36 }.freeze

      refine String do
        def colorize(code)
          "\033[#{CODES[code]}m#{self}\033[0m"
        end
      end
    end

    using ANSIColor

    attr_reader :ignore, :logger

    def initialize(ignore: [], logger: nil)
      @ignore = ignore
      @logger =
        logger ||
          Logger
            .new($stdout)
            .tap do |creating|
              creating.level = :info
              creating.formatter = ->(*, message) { message }
            end
    end

    def lint(*paths) # rubocop:disable Naming/PredicateMethod
      logger.info("Inspecting gemfiles at #{paths.join(", ")}\n")

      offenses = []
      paths.each do |path|
        Parser
          .for(path)
          .each_offense(ignore: ignore) do |offense|
            if offense
              offenses << offense
              logger.info("W".colorize(:magenta))
            else
              logger.info(".".colorize(:green))
            end
          end
      end

      logger.info("\n")

      if offenses.empty?
        true
      else
        messages =
          offenses.map do |offense|
            "#{offense.path.colorize(:cyan)}: " \
              "#{"W".colorize(:magenta)}: #{offense}"
          end

        logger.info("\nOffenses:\n\n#{messages.join("\n")}\n")
        false
      end
    end
  end

  class << self
    def dependencies
      @dependencies ||=
        SpellChecker.new(
          File.read(File.expand_path("gems.txt", __dir__)).split("\n")
        )
    end

    def remotes
      @remotes ||= SpellChecker.new(["https://rubygems.org/"])
    end

    def lint(*paths, ignore: [], logger: nil)
      Linter.new(ignore: ignore, logger: logger).lint(*paths)
    end
  end
end
