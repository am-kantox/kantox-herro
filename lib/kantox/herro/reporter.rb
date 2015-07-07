require 'kantox/herro/log'

module Kantox
  module Herro
    class ReporterError < ::StandardError
      def initialize msg, cause = nil
        super msg
        set_backtrace (@cause = cause) && @cause.backtrace || caller(1)
      end
      def cause
        @cause
      end
    end
    class Reporter
      STACK = []
      STACK_SIZE = Kantox::Herro.config.base!.stack || 20
      DEFAULT_ERROR = Kernel.const_get(Kantox::Herro.config.base!.error) rescue ::StandardError
      SPITTERS = Kantox::Herro.config.spitters || {}

      attr_reader :cause
      def initialize cause
        @cause =  case cause
                  when Exception then cause
                  when String then DEFAULT_ERROR.new(cause)
                  else DEFAULT_ERROR.new("#{cause}")
                  end
      end
      private :initialize

      def self.yo cause, level = 'info'
        message = Kantox::LOGGER.err((inst = Reporter.new(cause)).cause, 6)
        SPITTERS.each do |name, handlers|
          next unless handlers.active
          #  airbrake:
          #    signature: 'Airbrake.notify'
          #    sender: 'error_class'
          #    message: 'error_message'
          begin
            instance_eval "#{handlers.signature}('#{handlers.sender}' => '#{inst.cause.class}', '#{handlers.message}' => '#{message}')"
            Kantox::LOGGER.debug "Reported “«#{inst.cause.message}»” to «#{name}»"
          rescue => e
            Kantox::LOGGER.warn ReporterError.new("Problem reporting “«#{inst.cause.message}»” to «#{name}»", e), 5
          end
        end
        raise inst.cause
      end

    end
  end
end
