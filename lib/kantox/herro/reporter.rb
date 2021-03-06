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
                  else DEFAULT_ERROR.new(cause.to_s)
                  end
        @cause = ReportedError.new("Error ##{status} :: “#{@cause.message}”", @cause, status, **extended) if wrap
      end
      private :initialize

      def self.report cause, status = 200, except = [:all], wrap = true, **extended
        inst = Reporter.new(cause, status, wrap, **extended)
        meth, arg = case status
                    when 0...400 then [:dbg, cause]
                    when 400...500 then [:wrn, cause]
                    when 500...503 then [:err, inst.cause]
                    else [:ftl, inst.cause]
                    end
        Kantox::LOGGER.public_send(meth, *arg)

        SPITTERS.each do |name, handlers|
          next unless handlers.active
          next if except.is_a?(Array) && except != [:all] && except.include?(name)
          #  airbrake:
          #    signature: 'Airbrake.notify'
          #    sender: 'error_class'
          #    message: 'error_message'
          begin
            params = extended.merge(
              :type => meth,
              :cause => cause,
              :wrap => inst,
              :backtrace => caller,
              (handlers.sender || 'sender').to_sym => inst.cause.class.name,
              (handlers.message || 'message').to_sym => inst.cause.message
            ).reject do |_, v|
              v.nil? || v == 'nil'
            end
            method, target = handlers.signature.reverse.split(/\.|::/, 2).map(&:reverse)
            (target || 'Kernel').constantize.send(method, **params)

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

  def self.report cause, status = 200, except = [:all], **extended
    Kantox::Herro::Reporter.report cause, status, except, **extended
  end

  def self.error cause, status = 503, except = [:all], **extended
    Kantox::Herro::Reporter.error cause, status, except, **extended
  end
end
