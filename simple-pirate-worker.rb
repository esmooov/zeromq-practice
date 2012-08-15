#!/usr/bin/ruby

require 'rubygems'
require 'ffi-rzmq'
require 'debugger'

class LPWorker
  def initialize(connection,retries=nil,timeout=nil)
    @connection = connection
    @retries = (retries || 3).to_i
    @timeout = (timeout || 10).to_i
    @ctxt = ZMQ::Context.new(1)
    @socket = nil
    connect
    puts "Sending ready"
    status = @socket.send_string "\x00"
    puts "Foo"
    puts "STATUS: #{status}"
    at_exit do
      @socket.close
    end
  end

  def connect
    @socket = @ctxt.socket(ZMQ::REQ)
    @socket.setsockopt(ZMQ::LINGER,0)
    @socket.connect(@connection)
  end
  
  def work
    loop do
      m = []
      rc = @socket.recv_strings m
      addr = m.shift
      m.shift
      msg = m.shift
      puts "Got message:#{msg}"
      @socket.send_strings([addr,"",msg+" <- Roger that"])
    end
  end

end

if $0 == __FILE__
  worker = LPWorker.new("tcp://0.0.0.0:4446")
  worker.work
end
