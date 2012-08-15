#!/usr/bin/ruby

require 'rubygems'
require 'ffi-rzmq'
require 'debugger'

ctxt = ZMQ::Context.new(1)
frontend = ctxt.socket(ZMQ::ROUTER) 
backend = ctxt.socket(ZMQ::ROUTER)
frontend.setsockopt(ZMQ::LINGER,0)
backend.setsockopt(ZMQ::LINGER,0)
frontend.bind("tcp://0.0.0.0:4445")
backend.bind("tcp://0.0.0.0:4446")
workers = []
fpoll = ZMQ::Poller.new
bpoll = ZMQ::Poller.new
fpoll.register frontend, ZMQ::POLLIN
bpoll.register backend, ZMQ::POLLIN
timeout = 50
at_exit do
  frontend.close
  backend.close
end

loop do
  rc = fpoll.poll(50)
  items = fpoll.readables
  items.each do |i|
    m = []
    i.recv_strings m
    m.unshift ""
    w = workers.pop
    m.unshift w
    puts "Frontend sent me #{m}"
    status = backend.send_strings(m)
  end

  rc = bpoll.poll(50)
  items = bpoll.readables
  items.each do |i|
    m = []
    i.recv_strings m
    addr = m.shift
    m.shift
    msg = m[0]
    if msg == "\x00"
      workers << addr
      puts "Backend connected at #{addr}"
    else
      workers.unshift addr
      puts "Backend sent me #{m}"
      frontend.send_strings(m)
    end
  end
end
