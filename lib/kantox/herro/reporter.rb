require 'kantox/herro/log'

module Kantox
  module Herro
    class ReportedError < ::StandardError
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
      attr_accessor :extended

      def initialize cause
        @cause =  case cause
                  when Exception then cause
                  when String then DEFAULT_ERROR.new(cause)
                  else DEFAULT_ERROR.new("#{cause}")
                  end
      end
      private :initialize

      def self.error cause, except = [:all]
        message = Kantox::LOGGER.err((inst = Reporter.new(cause)).cause, 6)
        inst.extended = message

        SPITTERS.each do |name, handlers|
          next unless handlers.active
          next if except.is_a?(Array) && except != [:all] && except.include?(name)
          #  airbrake:
          #    signature: 'Airbrake.notify'
          #    sender: 'error_class'
          #    message: 'error_message'
          begin
            instance_eval "#{handlers.signature}('#{handlers.sender}' => '#{inst.cause.class}', '#{handlers.message}' => '#{message}')"
            Kantox::LOGGER.debug "Reported “«#{inst.cause.message}»” to «#{name}»"
          rescue => e
            Kantox::LOGGER.warn ReportedError.new("Problem reporting “«#{inst.cause.message}»” to «#{name}»", e), 5
          end
        end
        raise ReportedError.new(inst.cause)
      end
    end
  end
  def self.error cause, except = [:all]
    Kantox::Herro::Reporter.error cause, except
  end
end
