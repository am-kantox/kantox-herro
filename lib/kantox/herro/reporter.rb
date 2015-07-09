require 'kantox/herro/log'

module Kantox
  module Herro
    class ReportedError < ::StandardError
      attr_accessor :cause, :info, :extended
      def initialize msg = nil, cause = nil, info = nil, skip = 1, **extended
        @cause = cause
        super(msg || @cause && @cause.message || 'Reported error')
        set_backtrace(@cause && @cause.backtrace || caller(skip))
        @info = info || Kantox::LOGGER.format(self)
        @extended = {
          user: Thread.current[:user]
        }.merge extended
      end
    end
    class Reporter
      STACK = []
      STACK_SIZE = Kantox::Herro.config.base!.stack || 20
      DEFAULT_ERROR = Kernel.const_get(Kantox::Herro.config.base!.error) rescue ::StandardError
      SPITTERS = Kantox::Herro.config.spitters || {}

      attr_reader :cause

      def initialize cause, wrap = true, **extended
        @cause =  case cause
                  when Exception then cause
                  when String then DEFAULT_ERROR.new(cause)
                  else DEFAULT_ERROR.new("#{cause}")
                  end
        @cause = ReportedError.new("Error of type #{cause.class} occured.", @cause, **extended) if wrap
      end
      private :initialize

      def self.error cause, except = [:all], wrap = true, skip = 2, **extended
        Kantox::LOGGER.err((inst = Reporter.new(cause, wrap, **extended)).cause, 6)

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

        raise inst.cause
      end
    end
  end

  def self.error cause, except = [:all], wrap = true, **extended
    Kantox::Herro::Reporter.error cause, except, wrap, 3, **extended
  end
end
