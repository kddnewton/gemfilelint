# frozen_string_literal: true

require_relative 'lib/gemfilelint/version'

Gem::Specification.new do |spec|
  spec.name          = 'gemfilelint'
  spec.version       = Gemfilelint::VERSION
  spec.authors       = ['Kevin Newton']
  spec.email         = ['kddnewton@gmail.com']

  spec.summary       = 'Lint your Gemfile!'
  spec.homepage      = 'https://github.com/kddnewton/gemfilelint'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bundler'

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
end
