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
    Kantox::LOGGER.err 'I am an ERROR'

    Kantox::LOGGER.nfo ['I am an INFO WITH TRACE'], user: 'Aleksei', ip: '8.8.8.8'
    Kantox::LOGGER.dbg ['I am a DEBUG WITH TRACE']
  end

  it 'reports errors properly' do
    expect {Kantox.error 'Hey there'}.to raise_error(Kantox::Herro::ReportedError)
    expect {Kantox.error ArgumentError.new('I am an Argument Error'), user: 'Aleksei', ip: '8.8.8.8'}.to raise_error(Kantox::Herro::ReportedError)
  end

  it 'returns readable message and html' do
    msg = Kantox::LOGGER.wrn(['I am a WARNING WITH TRACE'])
    # puts "Readable message: #{msg.console_to_plain}"
    # expect(msg.console_to_html).to eq("<b><span style='color: #ffff00;'>✗ </span></b><b><span style='color: #ffff00;'>WAR</span></b> | <b><span style='color: #3f3f3f;'>20150708-100112.185</span></b> | <span style='color: #ffcc66;'>I am a WARNING WITH TRACE\n\u2BA9      ————————————————————————————————————————————————————————————————————————————————\n\u2BA9      [  0] </span><b><span style='color: #dfdfdf;'>/home/am/Proyectos/Kantox/kantox-herro/spec/kantox/herro_spec.rb<span style='color: #ffcc66;'>:</span><b><span style='color: #dfdfdf;'>32<span style='color: #ffcc66;'>: in </span><b><span style='color: #dfdfdf;'>block (2 levels) in <top (required)><span style='color: #ffcc66;'>\n\u2BA9      [  1] /home/am/.rvm/gems/ruby-2.1.1/gems/rspec-core-3.3.1/lib/rspec/core/example.rb:206:in </span><b><span style='color: #dfdfdf;'>instance_exec<span style='color: #ffcc66;'>\n\u2BA9      [  2] /home/am/.rvm/gems/ruby-2.1.1/gems/rspec-core-3.3.1/lib/rspec/core/example.rb:206:in </span><b><span style='color: #dfdfdf;'>block in run<span style='color: #ffcc66;'>\n\u2BA9      [  3] /home/am/.rvm/gems/ruby-2.1.1/gems/rspec-core-3.3.1/lib/rspec/core/example.rb:430:in </span><b><span style='color: #dfdfdf;'>block in with_around_and_singleton_context_hooks<span style='color: #ffcc66;'>\n\u2BA9      [  4] /home/am/.rvm/gems/ruby-2.1.1/gems/rspec-core-3.3.1/lib/rspec/core/example.rb:388:in </span><b><span style='color: #dfdfdf;'>block in with_around_example_hooks<span style='color: #ffcc66;'>\n\u2BA9      [  5] /home/am/.rvm/gems/ruby-2.1.1/gems/rspec-core-3.3.1/lib/rspec/core/hooks.rb:478:in </span><b><span style='color: #dfdfdf;'>block in run<span style='color: #ffcc66;'>\n\u2BA9      [  6] /home/am/.rvm/gems/ruby-2.1.1/gems/rspec-core-3.3.1/lib/rspec/core/hooks.rb:616:in </span><b><span style='color: #dfdfdf;'>run_around_example_hooks_for<span style='color: #ffcc66;'>\n\u2BA9      [  7] /home/am/.rvm/gems/ruby-2.1.1/gems/rspec-core-3.3.1/lib/rspec/core/hooks.rb:478:in </span><b><span style='color: #dfdfdf;'>run<span style='color: #ffcc66;'>\n\u2BA9      .......................................................................[22 more]\n\u2BA9      ================================================================================</span>\n")
    # puts "HTML message: #{msg.console_to_html}"
  end

  it 'converts console colors to html' do
    str = "\e[01;38;05;21mHello\e[0m, \e[04;38;05;156mworld!\e[0m"
    expect(str.console_to_html).to eq ("<div style=\"background-color:#080820;padding:1em;\"><b><span style='color: #0000ff;'>Hello</span></b>, <u><span style='color: #99ff66;'>world!</span></u></div>")
  end
end
