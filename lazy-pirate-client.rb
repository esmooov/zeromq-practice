#!/usr/bin/ruby

require 'rubygems'
require 'ffi-rzmq'

class LPClient
  def initialize(connection,retries=nil,timeout=nil)
    @connection = connection
    @retries = (retries || 30).to_i
    @timeout = (timeout || 100).to_i
    @ctxt = ZMQ::Context.new(1)
    @poller = ZMQ::Poller.new
    @socket = nil
    reconnect
    at_exit do
      @socket.close
    end
  end

  def reconnect
    if @socket
      @poller.deregister @socket, ZMQ::POLLIN
      @socket.close
      puts "Reconnecting"
    end
    @socket = @ctxt.socket(ZMQ::REQ)
    @socket.setsockopt(ZMQ::LINGER,0)
    @socket.connect(@connection)
    @poller.register @socket, ZMQ::POLLIN
  end
  
  def send(message)
    done = false
    @retries.times do |tries|
      break if done
      send_status = @socket.send_string(message)
      rc = @poller.poll(@timeout)
      puts "S: #{send_status} RC: #{rc}"
      if rc == 0 || rc == -1
        reconnect
      else
        items = @poller.readables
        items.each do |i|
          m = ""
          i.recv_string(m)
          puts m
          done = true
        end
      end
    end
  end

end

if $0 == __FILE__
  client = LPClient.new("tcp://0.0.0.0:4445")
  loop do
    msg = gets
    puts "Sending #{msg}"
    msg = msg.chomp
    client.send(msg) 
  end
end
