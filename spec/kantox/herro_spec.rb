require 'spec_helper'

describe Kantox::Herro do
  it 'has a version number' do
    expect(Kantox::Herro::VERSION).not_to be nil
  end

  it 'loads config properly' do
    expect(Kantox::Herro.config.base!.stack).to eq(20)
  end

  it 'logs out the exception' do
    Kantox::LOGGER.err ArgumentError.new('I am an Argument Error'), 5

    Kantox::LOGGER.wrn 'I am a WARNING'
    Kantox::LOGGER.err 'I am an ERROR'
    Kantox::LOGGER.nfo 'I am an INFO'
    Kantox::LOGGER.dbg 'I am a DEBUG'

    Kantox::LOGGER.wrn ['I am a WARNING WITH TRACE']
    Kantox::LOGGER.err ['I am an ERROR WITH TRACE']
    Kantox::LOGGER.nfo ['I am an INFO WITH TRACE']
    Kantox::LOGGER.dbg ['I am a DEBUG WITH TRACE']
  end

  it 'reports errors properly' do
    expect {Kantox::Herro::Reporter.yo 'Hey there'}.to raise_error(StandardError)
    expect {Kantox::Herro::Reporter.yo ArgumentError.new('I am an Argument Error')}.to raise_error(ArgumentError)
  end

end
