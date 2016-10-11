# FluentLoggerSinatra

[![Build Status](https://travis-ci.org/sliuu/fluent-logger-sinatra.svg)][travis]

[travis]: https://travis-ci.org/sliuu/fluent-logger-sinatra

Fluent Logger Sinatra was made for Sinatra apps, but can also be used in Ruby on Rails applications, if you'd
like multiple loggers in your application to log specific things.

If you're converting from using Loggers in your app, fluent-logger-ruby does not
support the basic methods that the Ruby Logger does, like info, warn, error, etc.

Especially if you're using a gem that logs in the background, like Delayed Job,
Delayed Job will expect to be able to call info, debug, etc. on the logger you
provide it.

In addition, Sinatra applications expect to be able to call the method write
on any logger you provide it. So here's the solution: fluent-logger-sinatra!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-logger-sinatra'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-logger-sinatra

## Usage

Initalize an instance of the logger
The first argument is the tag prefix, the second argument is an option tag suffix, the third is the host IP, and the fourth is the port number

```ruby
logger = FluentLoggerSinatra::Logger.new('myapp', 'delayed_job', '127.0.0.1', 24224)
logger.info("Delayed Job running on port ###")
```

If you're using a Sinatra app:
```ruby
use ::Rack::CommonLogger, logger
```

## Changelog
### [0.2.0]
- Included severity and module name in model.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sliuu/fluent-logger-sinatra. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
