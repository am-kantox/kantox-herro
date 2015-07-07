require 'pry'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'kantox/herro'

unless Kernel.const_defined? 'Kantox::Exceptions::StandardError'
  module Kantox
    module Exceptions
      class StandardError < ::StandardError ; end
    end
  end
end
