# Gemfile lint

[![Build Status](https://github.com/kddeisz/gemfilelint/workflows/Main/badge.svg)](https://github.com/kddeisz/gemfilelint/actions)
[![Gem Version](https://img.shields.io/gem/v/gemfilelint.svg)](https://github.com/kddeisz/gemfilelint)

Lint your Gemfile! This will find common spelling mistakes in gems and remote sources so that you don't accidentally download code from places that you don't mean to. For example, if you have a Gemfile with the contents:

```ruby
source 'https://rubyems.org'

gem 'rails'
gem 'puma'
gem 'pg'
```

You might not be able to see the immediate issue, but there's a typo in your source declaration. While this will generally be harmless, as it will likely error, it's also possible that someone could register that domain and provide gems with modified content to execute their own code on your production system.

`gemfilelint` is a utility that you can run against your Gemfile that will check all of your listed sources against known trusted sources and all of your listed gems against the most commonly downloaded gems according to rubygems. This can give you some peace of mind that if you make a spelling mistake you won't accidentally open yourself up to RCE without knowing it.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gemfilelint'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install gemfilelint

## Usage

Run the `gemfilelint` executable either in the root of your repository that contains a Gemfile or specify a path to one or more Gemfile paths.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kddeisz/gemfilelint. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kddeisz/gemfilelint/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Gemfilelint project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kddeisz/gemfilelint/blob/master/CODE_OF_CONDUCT.md).
