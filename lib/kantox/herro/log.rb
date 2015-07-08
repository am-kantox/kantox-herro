require 'logger'

module Kantox
  module Herro
    class Log
      TERMINAL_WIDTH = Kantox::Herro.config.log!.terminal || 80
      NESTED_OFFSET = Kantox::Herro.config.log!.nested || 30
      BACKTRACE_LENGTH = Kantox::Herro.config.log!.backtrace!.len || 10
      BACKTRACE_SKIP = Kantox::Herro.config.log!.backtrace!.skip || 5

      APP_ROOT = Kantox::Herro.config.log!.root ||
        Kernel.const_defined?('::Rails') && Kernel.const_get('::Rails').root ||
        __dir__.split(File::SEPARATOR)[0..4].join(File::SEPARATOR)

      SEV_COLORS_DEF = Kantox::Herro.config.log!.colors!
      SEV_COLORS = {
        'INFO'    => [SEV_COLORS_DEF.info!.label || '01;38;05;21',  SEV_COLORS_DEF.info!.text || '00;38;05;110'],
        'WARN'    => [SEV_COLORS_DEF.warn!.label || '01;38;05;226', SEV_COLORS_DEF.warn!.text || '00;38;05;222'],
        'ERROR'   => [SEV_COLORS_DEF.error!.label || '01;38;05;196', SEV_COLORS_DEF.error!.text || '01;38;05;174'],
        'DEBUG'   => [SEV_COLORS_DEF.debug!.label || '01;38;05;242', SEV_COLORS_DEF.debug!.text || '00;38;05;246'],
        'ANY'     => [SEV_COLORS_DEF.any!.label || '01;38;05;222;48;05;238', SEV_COLORS_DEF.any!.text || '01;38;05;253;48;05;238']
      }
      SEV_SYMBOLS = {
        'INFO'    => Kantox::Herro.config.log!.symbols!.info || '✔',
        'WARN'    => Kantox::Herro.config.log!.symbols!.warn || '✗',
        'ERROR'   => Kantox::Herro.config.log!.symbols!.error || '✘',
        'DEBUG'   => Kantox::Herro.config.log!.symbols!.debug || '✓',
        'ANY'     => Kantox::Herro.config.log!.symbols!.any || '▷'
      }
      HIGHLIGHT_COLOR = SEV_COLORS_DEF.highlight || '01;38;05;51'
      EXCEPTION_COLOR = SEV_COLORS_DEF.exception || '01;38;05;88'
      APPDIR_COLOR = SEV_COLORS_DEF.root || '01;38;05;253'
      METHOD_COLOR = SEV_COLORS_DEF[:method] || '01;38;05;253'

      STOPWORDS = Kantox::Herro.config.log!.stopwords.map(&Regexp.method(:new)) || []

      attr_reader :tty, :logger

      def initialize log = nil
        @logger, @log = case
                        when log then [log, log]
                        when Kernel.const_defined?('::Rails')
                          l = Kernel.const_get('::Rails')
                          [ l, l.instance_variable_get(:@logger).instance_variable_get(:@log) ]
                        else
                          l = Logger.new($stdout)
                          [l, l]
                        end
        @tty = @log.respond_to?(:tty?) && @log.tty? ||
               (l = @log.instance_variable_get(:@logdev)
                        .instance_variable_get(:@dev)) && l.tty? ||
               Kernel.const_defined?('::Rails') && Kernel.const_get('::Rails').env.development?

        @log.formatter = proc do |severity, datetime, progname, message|
          message unless STOPWORDS.any? { |sw| message =~ sw }
        end
      end

      %i(warn info error debug).each do |m|
        class_eval "
          def #{m} what, skip = BACKTRACE_SKIP
            prepare_for_log(what, '#{m.upcase}', nil, skip).tap do |prepared|
              logger.#{m}(prepared)
            end.gsub(/\\e\\[.*?m/, '')
          end
        "
      end
      alias_method :wrn, :warn
      alias_method :inf, :info
      alias_method :nfo, :info
      alias_method :err, :error
      alias_method :dbg, :debug

    private

      def clrz txt, clr
        return txt unless @tty

        txt = "#{txt}".gsub(/«(.*?)»/, "\e[#{HIGHLIGHT_COLOR}m\\1\e[#{clr}m")
                      .gsub(/⟨(.*?)⟩/, "\e[#{EXCEPTION_COLOR}m\\1\e[#{clr}m")
                      .gsub(/⟦(.*?)⟧/, "\e[#{APPDIR_COLOR}m\\1\e[#{clr}m")
                      .gsub(/⟬(.*?)⟭/, "\e[#{METHOD_COLOR}m\\1\e[#{clr}m")


        "\e[#{clr}m#{txt}\e[0m"
      end

      def prepare_for_log what, severity = Logger::ERROR, datetime = nil, skip = BACKTRACE_SKIP
        case what
        when Exception then log_exception what, severity, datetime, skip
        when Array then log_with_trace what.first, severity, datetime, skip
        else log_string what, severity
        end
      end

      def preen_backtrace backtrace_or_caller
        backtrace_or_caller.map.with_index do |bt, idx|
          if idx < BACKTRACE_LENGTH || bt =~ /^#{APP_ROOT}/
            "[#{idx.to_s.rjust(3, ' ')}] " << \
              bt.gsub(/^(#{APP_ROOT}[^:]*):(\d+):/, "⟦\\1⟧:⟦\\2⟧: ")
                .gsub(/`(.*?)'/, "⟬\\1⟭")
          else
            nil
          end
        end.compact
      end

      def preen_exception e, skip
        bt = e.backtrace.is_a?(Array) ? e.backtrace[skip..-1] : caller(skip)
        pbt = preen_backtrace(bt)
        {
          causes: loop.inject({causes: [], current: e}) do |memo|
                    memo[:causes] << memo[:current]
                    memo[:current] = memo[:current].cause
                    break memo unless memo[:current]
                    memo
                  end[:causes].reverse,
          backtrace: pbt,
          omitted: bt.size - pbt.size
        }
      end

      def just offset = NESTED_OFFSET, sym = ' '
        "#{$/}⮩ #{sym * (offset - 2)}"
      end

      def delim sym = '—'
        "#{just << ''.ljust(TERMINAL_WIDTH, sym)}"
      end

      def format_exception e, skip
        pe = preen_exception e, skip

        "Exception: ⟨#{pe[:causes].map(&:class).join(' ⇒ ')}⟩ |" \
          << delim \
          << just << pe[:causes].map { |c| "⟨#{c.class}⟩ :: #{c.message}" }.join(just) \
          << delim \
          << just << pe[:backtrace].join(just) \
          << just << "[#{pe[:omitted]} more]".rjust(TERMINAL_WIDTH, '.') \
          << just << ''.ljust(TERMINAL_WIDTH, '=')
      end

      def log_exception e, severity = Logger::INFO, datetime, skip
        log_string format_exception(e, skip), severity, datetime
      end

      def log_with_trace s, severity = Logger::INFO, datetime, skip
        bt = caller(skip)
        pbt = preen_backtrace bt
        with_bt = s \
                  << delim \
                  << just << pbt.join(just) \
                  << just << "[#{bt.size - pbt.size} more]".rjust(TERMINAL_WIDTH, '.') \
                  << just << ''.ljust(TERMINAL_WIDTH, '=')
        log_string with_bt, severity, datetime
      end

      def log_string s, severity = Logger::INFO, datetime = nil
        datetime ||= Time.now
        severity = ::Logger::SEV_LABEL[severity] if Integer === severity
        '' << clrz("#{SEV_SYMBOLS[severity]} ", SEV_COLORS[severity].first)    \
               << clrz(severity[0..2], SEV_COLORS[severity].first)             \
               << ' | '                                                        \
               << clrz(datetime.strftime('%Y%m%d-%H%M%S.%3N'), '01;38;05;238') \
               << ' | '                                                        \
               << clrz(s, SEV_COLORS[severity].last)                           \
               << "\n"
      end
    end
  end
  LOGGER = Herro::Log.new
end
