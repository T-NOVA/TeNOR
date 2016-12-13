require "fluent-logger"
require "fluent-logger-sinatra/version"

module FluentLoggerSinatra
  class Logger
    attr_accessor :tag
    attr_accessor :logger
    attr_accessor :logger_console

    def initialize(app, tag, host, port)
      @logger_console = Fluent::Logger::ConsoleLogger.open($stdout)
      @logger = Fluent::Logger::FluentLogger.new(app, :host => host, :port => port)
      @tag = tag
    end
    def debug(message)
      logger_console.post_text("D, [#{Time.now}]  DEBUG -- : #{message}")
      logger.post(tag, { module: @tag, severity: 'debug', msg: message })
    end
    def info(message)
      logger_console.post_text("I, [#{Time.now}]  INFO -- : #{message}")
      logger.post(tag, { module: @tag, severity: 'info', msg: message })
    end
    def warn(message)
      logger_console.post_text("W, [#{Time.now}]  WARN -- : #{message}")
      logger.post(tag, { module: @tag, severity: 'warn', msg: message })
    end
    def error(message)
      logger_console.post_text("R, [#{Time.now}]  ERROR -- : #{message}")
      logger.post(tag, { module: @tag, severity: 'error', msg: message })
    end
    def fatal(message)
      logger_console.post_text("F, [#{Time.now}]  FATAL -- : #{message}")
      logger.post(tag, { module: @tag, severity: 'fatal', msg: message })
    end
    def write(message)
      logger.post(tag, { write: message })
    end
  end
end
