require 'jwt'
require 'net/http'
require 'json'
require 'logger'
require 'time'

module SignInWithAppleUserMigrator
  class AuthorizationError < StandardError; end

  class Base
    attr_reader :logger

    def initialize()
      @logger = setup_logger
    end

    private
      def setup_logger
        logger = Logger.new(STDOUT)
        log_level = parse_log_level(ENV['LOG_LEVEL'])
        logger.level = log_level
        logger
      end

      def parse_log_level(level)
        case level.to_s.upcase
        when 'DEBUG' then Logger::DEBUG
        when 'INFO'  then Logger::INFO
        when 'WARN'  then Logger::WARN
        when 'ERROR' then Logger::ERROR
        when 'FATAL' then Logger::FATAL
        else Logger::INFO
        end
      end
  end
end
