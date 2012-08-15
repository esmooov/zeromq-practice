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
    at_exit do
      @socket.close
    end
  end

  def connect
    @socket = @ctxt.socket(ZMQ::REP)
    @socket.setsockopt(ZMQ::LINGER,0)
    @socket.bind(@connection)
  end
  
  def work
    loop do
      received_msg = ZMQ::Message.new
      rc = @socket.recvmsg(received_msg)
      puts "Got message:#{received_msg.copy_out_string}"
      new_msg = ZMQ::Message.new(received_msg.copy_out_string+" -Gotcha")
      @socket.sendmsg(new_msg)
    end
  end

end

if $0 == __FILE__
  worker = LPWorker.new("tcp://0.0.0.0:4445")
  worker.work
end
