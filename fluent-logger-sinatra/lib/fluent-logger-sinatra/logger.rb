require "fluent-logger"
require "fluent-logger-sinatra/version"

module FluentLoggerSinatra
  class Logger
    attr_accessor :tag
    attr_accessor :logger

    def initialize(app, tag, host, port)
      @logger = Fluent::Logger::FluentLogger.new(app, :host => host, :port => port)
      @tag = tag
    end
    def debug(message)
      logger.post(tag, { module: @tag, severity: 'debug', msg: message })
    end
    def info(message)
      logger.post(tag, { module: @tag, severity: 'info', msg: message })
    end
    def warn(message)
      logger.post(tag, { module: @tag, severity: 'warn', msg: message })
    end
    def error(message)
      logger.post(tag, { module: @tag, severity: 'error', msg: message })
    end
    def fatal(message)
      logger.post(tag, { module: @tag, severity: 'fatal', msg: message })
    end
    def write(message)
      logger.post(tag, { write: message })
    end
  end
end
