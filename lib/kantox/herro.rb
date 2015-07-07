require 'kungfuig'
require 'kantox/herro/version'

module Kantox
  # Usage:
  #      Herro.config('config/herro.yml') do |options|
  #      end
  #
  module Herro
    include Kungfuig
    config('config/herro.yml')
  end
end

require 'kantox/herro/log'
require 'kantox/herro/reporter'
