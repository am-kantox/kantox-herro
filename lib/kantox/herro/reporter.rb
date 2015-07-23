require 'kantox/herro/log'

module Kantox
  module Herro
    class ReportedError < ::StandardError
      attr_accessor :cause, :status, :info, :extended
      def initialize msg = nil, cause = nil, status = 503, info = nil, skip = 1, **extended
        @cause = cause
        @status = status
        super(msg || @cause && @cause.message || 'Reported error')
        set_backtrace(@cause && @cause.backtrace || caller(skip))
        @extended = extended
        @info = info || Kantox::LOGGER.format(self)
      end
    end
    class Reporter
      STACK = []
      STACK_SIZE = Kantox::Herro.config.base!.stack || 20
      DEFAULT_ERROR = Kernel.const_get(Kantox::Herro.config.base!.error) rescue ::StandardError
      SPITTERS = Kantox::Herro.config.spitters || {}

      attr_reader :cause

      def initialize cause, status, wrap = true, **extended
        @cause =  case cause
                  when Exception then cause
                  when String then DEFAULT_ERROR.new(cause)
                  else DEFAULT_ERROR.new("#{cause}")
                  end
        @cause = ReportedError.new("Error ##{status} :: “#{@cause.message}”", @cause, status, **extended) if wrap
      end
      private :initialize

      def self.report cause, status = 200, except = [:all], wrap = true, **extended
        Kantox::LOGGER.err((inst = Reporter.new(cause, status, wrap, **extended)).cause)

        SPITTERS.each do |name, handlers|
          next unless handlers.active
          next if except.is_a?(Array) && except != [:all] && except.include?(name)
          #  airbrake:
          #    signature: 'Airbrake.notify'
          #    sender: 'error_class'
          #    message: 'error_message'
          begin
            instance_eval "#{handlers.signature}('#{handlers.sender}' => '#{inst.cause.class}', '#{handlers.message}' => \%Q{#{inst.cause.message}})"
            Kantox::LOGGER.debug "Reported “«#{inst.cause.message}»” to «#{name}»"
          rescue => e
            Kantox::LOGGER.debug ReportedError.new("Problem reporting “«#{inst.cause.message}»” to «#{name}»", e, extended)
          end
        end

        inst
      end

      def self.error cause, status = 503, except = [:all], wrap = true, **extended
        raise self.report(cause, status, except, wrap, **extended).cause
      end
    end
  end

  def self.report cause, except = [:all], **extended
    Kantox::Herro::Reporter.report cause, 200, except, **extended
  end
  def self.error cause, status = 503, except = [:all], **extended
    Kantox::Herro::Reporter.error cause, status, except, **extended
  end
end
