# encoding: utf-8
#
$: << File.realpath(File.join(File.dirname(__FILE__), "..", "lib"))
require "json"
require "lumberjack/server"
require "stud/try"
require "stud/temporary"

describe "lumberjack" do
  let(:ssl_certificate) { Stud::Temporary.pathname("ssl_certificate") }
  let(:ssl_key) { Stud::Temporary.pathname("ssl_key") }
  let(:config_file) { Stud::Temporary.pathname("config_file") }
  let(:input_file) { Stud::Temporary.pathname("input_file") }

  let(:lsf) do
    # Start the process, return the pid
    IO.popen(["./logstash-forwarder", "-config", config_file])
  end

  let(:random_field) { (rand(30)+1).times.map { (rand(26) + 97).chr }.join }
  let(:random_value) { (rand(30)+1).times.map { (rand(26) + 97).chr }.join }

  let(:server) do 
    Lumberjack::Server.new(:ssl_certificate => ssl_certificate, :ssl_key => ssl_key)
  end
  let(:queue) { Queue.new }

  let(:server_thread) do
    Thread.new(queue) do |q| 
      begin
        server.run { |e| q << e }
      rescue => e
        puts "Lumberjack::Server failed: #{e}"
        puts e.backtrace
        raise e
      end
    end
  end

  let(:logstash_forwarder_config) do
    <<-CONFIG
    {
      "network": {
        "servers": [ "localhost:5043" ],
        "ssl ca": "#{ssl_certificate}"
      },
      "files": [
        {
          "paths": [ "#{input_file}", ],
          "fields": { #{random_field.to_json}: #{random_value.to_json} }
        }
      ]
    }
    CONFIG
  end

  after do
    [ssl_certificate, ssl_key, config_file].each do |path|
      File.unlink(path) if File.exists?(path)
    end
    Process::kill("KILL", lsf.pid)
    Process::wait(lsf.pid)
  end

  before do
    system("openssl req -x509  -batch -nodes -newkey rsa:2048 -keyout #{ssl_key} -out #{ssl_certificate} -subj /CN=localhost > /dev/null 2>&1")
    
    lsf
    server_thread
  end # before each


  it "should follow a file and emit lines as events" do
    fd = File.new(input_file, "w")
    fd.write("Hello world\n")
    fd.flush
    fd.close
    p server
    p lsf.pid


    p queue.pop
  end

  it "should follow a slowly-updating file and emit lines as events"
  it "should support unicode text"
end
