# Kantox::Herro

```ruby
it 'has a version number' do
  expect(Kantox::Herro::VERSION).not_to be nil
end

it 'loads config properly' do
  expect(Kantox::Herro.config.base!.stack).to eq(20)
end

it 'logs out the exception' do
  Kantox::LOGGER.err ArgumentError.new('I am an Argument Error'), 5

  Kantox::LOGGER.wrn 'I am a WARNING'
  Kantox::LOGGER.err 'I am an ERROR'
  Kantox::LOGGER.nfo 'I am an INFO'
  Kantox::LOGGER.dbg 'I am a DEBUG'

  Kantox::LOGGER.wrn ['I am a WARNING WITH TRACE']
  Kantox::LOGGER.err ['I am an ERROR WITH TRACE']
  Kantox::LOGGER.nfo ['I am an INFO WITH TRACE']
  Kantox::LOGGER.dbg ['I am a DEBUG WITH TRACE']
end

it 'reports errors properly' do
  expect {Kantox::Herro::Reporter.error 'Hey there'}.to raise_error(StandardError)
  expect {Kantox.error ArgumentError.new('I am an Argument Error')}.to raise_error(ArgumentError)
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kantox-herro'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kantox-herro

## Usage

```ruby
  # Write log message, throw wrapped into `ReportedError` original exception:
  Kantox.error ArgumentError.new('I am an Argument Error')

  # Write log message including stack trace, return clean formatted text:
  formatted = Kantox::LOGGER.wrn ['Warning']
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kantox-herro. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
