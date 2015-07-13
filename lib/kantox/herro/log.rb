require 'logger'
require 'io/console'

module Kantox
  module Herro
    class Log
      NESTED_OFFSET = Kantox::Herro.config.log!.nested || 30
      TERMINAL_WIDTH = Kantox::Herro.config.log!.terminal || ($stdin.winsize.last rescue 80) - NESTED_OFFSET
      BACKTRACE_LENGTH = Kantox::Herro.config.log!.backtrace!.len || 10
      BACKTRACE_SKIP = Kantox::Herro.config.log!.backtrace!.skip || 0

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
      DATETIME_COLOR = SEV_COLORS_DEF.datetime || '01;38;05;240'
      EXTENDED_COLOR = SEV_COLORS_DEF.extended || '01;38;05;246'

      STOPWORDS = Kantox::Herro.config.log!.stopwords.map(&Regexp.method(:new)) || []

      FORMATTER = Kantox::Herro.config.log!.formatters![
        Kernel.const_defined?('::Rails') && Kernel.const_get('::Rails').env.to_sym] ||
        Kantox::Herro.config.log!.formatters![:standalone] || 'default'

      def initialize log = nil
        ensure_logger(log) if log
      end

      def logger
        ensure_logger
      end

      def format what
        prepare_for_log what
      end

      %i(warn info error debug).each do |m|
        class_eval "
          def #{m} what, skip = BACKTRACE_SKIP, datetime = nil, **extended
            logger.#{m} what.is_a?(String) ? preen_string(what.strip) + format_extended(extended) : what
            prepare_for_log what, '#{m}'.upcase, datetime, skip, **extended
          end
        "
      end
      alias_method :wrn, :warn
      alias_method :inf, :info
      alias_method :nfo, :info
      alias_method :err, :error
      alias_method :dbg, :debug

    private

      def ensure_logger log = nil
        return @log if @log

        @logger, @log = case
                        when log then [log, log]
                        when Kernel.const_defined?('::Rails')
                          l = Kernel.const_get('::Rails').logger
                          [ l, l.instance_variable_get(:@logger).instance_variable_get(:@log) ]
                        else
                          l = Logger.new($stdout)
                          [l, l]
                        end
        @tty = @log.respond_to?(:tty?) && @log.tty? ||
               (l = @log.instance_variable_get(:@logdev)
                        .instance_variable_get(:@dev)) && l.tty? ||
               Kernel.const_defined?('::Rails') && Kernel.const_get('::Rails').env.development?

        @formatter = @log.formatter
        case FORMATTER
        when 'extended'
          @log.formatter = proc do |severity, datetime, progname, message|
            message += " [this is a stub]"  # FIXME add significant info
            @formatter.call severity, datetime, progname, message
          end
        when 'pretty'
          @log.formatter = proc do |severity, datetime, progname, message|
            prepare_for_log(message, severity, datetime, BACKTRACE_SKIP) \
              unless message.is_a?(String) && message.strip.empty? || STOPWORDS.any? { |sw| message =~ sw }
          end
        when 'filtered'
          @log.formatter = proc do |severity, datetime, progname, message|
            msg = case message
                  when Exception then message.message
                  when String then message
                  else "#{message}"
                  end.strip
            @formatter.call(severity, datetime, progname, message) \
              unless msg.empty? || STOPWORDS.any? { |sw| msg =~ sw }
          end
        else # do nothing
        end

        @log
      end

      def clrz txt, clr
        return txt unless @tty && (!Kernel.const_defined?('::Rails') || Kernel.const_get('::Rails').env.development?)

        txt = "#{txt}".gsub(/«(.*?)»/m, "\e[#{HIGHLIGHT_COLOR}m\\1\e[#{clr}m")
                      .gsub(/⟨(.*?)⟩/m, "\e[#{EXCEPTION_COLOR}m\\1\e[#{clr}m")
                      .gsub(/⟦(.*?)⟧/m, "\e[#{APPDIR_COLOR}m\\1\e[#{clr}m")
                      .gsub(/⟬(.*?)⟭/m, "\e[#{METHOD_COLOR}m\\1\e[#{clr}m")
                      .gsub(/⟪(.*?)⟫/m, "\e[#{EXTENDED_COLOR}m\\1\e[#{clr}m")


        "\e[#{clr}m#{txt}\e[0m"
      end

      def prepare_for_log what, severity = Logger::ERROR, datetime = nil, skip = BACKTRACE_SKIP, **extended
        case what
        when Exception then log_exception what, severity, datetime, skip, **extended
        when Array then log_with_trace what.first, severity, datetime, skip, **extended
        else log_string preen_string(what.to_s), severity, datetime, **extended
        end
      end

      def preen_backtrace backtrace_or_caller
        backtrace_or_caller.map.with_index do |bt, idx|
          if idx < BACKTRACE_LENGTH || bt =~ /^#{APP_ROOT}/
            "[#{idx.to_s.rjust(3, ' ')}] " << \
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

      def preen_string s
        s.gsub /\s*\R\s*/, just
      end

      def just offset = NESTED_OFFSET, sym = ' '
        "#{$/}⮩ #{sym * (offset - 2)}"
      end

      def delim sym = '—'
        "#{just << ''.ljust(TERMINAL_WIDTH, sym)}"
      end

      def format_extended extended
        if extended.empty?
          ''
        else
          '' << delim << just << extended.map do |k, v|
            # FIXME expand extended
            '⟪' << k.to_s.rjust(NESTED_OFFSET + 13, ' ') << '⟫ | ⟦' << (v ? "#{v}" : '✗') << '⟧'
          end.join(just) << delim
        end
      end

      def format_exception e, skip
        pe = preen_exception e, skip

        extended = e.respond_to?(:extended) && e.extended ? format_extended(e.extended) : ''

        "Exception: ⟨#{pe[:causes].map(&:class).join(' ⇒ ')}⟩ |"                       \
          << delim                                                                     \
          << just << pe[:causes].map { |c| "⟨#{c.class}⟩ :: #{preen_string c.message}" }.join(just) \
          << delim                                                                     \
          << just << pe[:backtrace].join(just)                                         \
          << just << "[#{pe[:omitted]} more]".rjust(TERMINAL_WIDTH, '.')               \
          << extended
      end

      def log_exception e, severity, datetime, skip, **extended
        log_string format_exception(e, skip), severity, datetime, **extended
      end

      def log_with_trace s, severity, datetime, skip, **extended
        bt = caller(skip)
        pbt = preen_backtrace bt
        with_bt = s \
                  << delim \
                  << just << pbt.join(just) \
                  << just << "[#{bt.size - pbt.size} more]".rjust(TERMINAL_WIDTH, '.') \
                  << delim
        log_string with_bt, severity, datetime, **extended
      end

      def log_string s, severity, datetime = nil, **extended
        datetime ||= Time.now
        severity = ::Logger::SEV_LABEL[severity] if Integer === severity
        '' << clrz("#{SEV_SYMBOLS[severity]} ", SEV_COLORS[severity].first)    \
               << clrz(severity[0..2], SEV_COLORS[severity].first)             \
               << ' | '                                                        \
               << clrz(datetime.strftime('%Y%m%d-%H%M%S.%3N'), DATETIME_COLOR) \
               << ' | '                                                        \
               << clrz(s, SEV_COLORS[severity].last)                           \
               << "\n"
      end
    end
  end
  LOGGER = Herro::Log.new unless Kernel.const_defined?('::Rails')
end
