require 'kungfuig'
require 'kantox/herro/version'

module Kantox
  # Usage:
  #      Herro.config('config/herro.yml') do |options|
  #        options.life = 42
  #      end
  #
  module Herro
    include Kungfuig
    config('config/herro.yml')
  end
end

require 'kantox/herro/monkeypatches'
require 'kantox/herro/log'
require 'kantox/herro/reporter'

module Kantox
  class HackMiddlewareSettings
    MAXREADLEN = 2048

    def initialize(app, logger)
      @app, @logger = app, logger
      @rp, @wp = IO.pipe

      Thread.new do
        loop do
          begin
            Kantox::LOGGER.rack @rp.read_nonblock(MAXREADLEN)
          rescue IO::WaitReadable
            IO.select([@rp])
            retry
          end
        end
      end
    end

    def call(env)
      IO.select(nil, [env['rack.errors'] = @wp])
      @app.call(env)
    end
  end
end
