require 'spec_helper'

describe Kantox::Herro do
  it 'has a version number' do
    expect(Kantox::Herro::VERSION).not_to be nil
  end

  it 'loads config properly' do
    expect(Kantox::Herro.config.base!.stack).to eq(20)
  end

  it 'logs out the exception' do
    Kantox::LOGGER.err ArgumentError.new('Hi! I am an Argument Error')

    Kantox::LOGGER.wrn 'I am a WARNING', user: 'Aleksei', ip: '8.8.8.8'
    Kantox::LOGGER.ftl 'I am an ERROR'

    Kantox::LOGGER.nfo ['I am an INFO WITH TRACE'], user: 'Aleksei', ip: '8.8.8.8'
    Kantox::LOGGER.dbg ['I am a DEBUG WITH TRACE']
  end

  it 'reports errors properly' do
    expect {Kantox.report 'Hey there'}.not_to raise_error
    expect {Kantox.error 'Hey there'}.to raise_error(Kantox::Herro::ReportedError)
    expect {Kantox.error ArgumentError.new('I am an Argument Error'), user: 'Aleksei', ip: '8.8.8.8'}.to raise_error(Kantox::Herro::ReportedError)
  end

  it 'returns readable message and html' do
    Kantox::LOGGER.wrn(['I am a WARNING WITH TRACE'])
  end

  it 'converts console colors to html' do
    str = "\e[01;38;05;21mHello\e[0m, \e[04;38;05;156mworld!\e[0m"
    expect(str.console_to_html).to eq ("<div style=\"background-color:#080820;padding:1em;\"><b><span style='color: #0000ff;'>Hello</span></b>, <u><span style='color: #99ff66;'>world!</span></u></div>")
  end
end
