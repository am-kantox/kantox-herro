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

  class HackMiddlewareSettings
    def initialize(app, logger)
      @app, @logger = app, logger
    end

    def call(env)
      env['rack.errors'] = Rails.logger.instance_variable_get(:@logger).instance_variable_get(:@log_dest)
      @app.call(env)
    end
  end
end

require 'kantox/herro/monkeypatches'
require 'kantox/herro/log'
require 'kantox/herro/reporter'
