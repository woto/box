#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../../lib", __FILE__)
require "nio"
require "socket"
require 'json'

# Echo server example written with nio4r
class EchoServer
  def initialize(host, port)
    @selector = NIO::Selector.new

    puts "Listening on #{host}:#{port}"
    @server = TCPServer.new(host, port)

    monitor = @selector.register(@server, :r)
    monitor.value = proc { accept }
  end

  def run
    loop do
      @selector.select { |monitor| monitor.value.call(monitor) }
    end
  end

  def accept
    socket = @server.accept
    _, port, host = socket.peeraddr
    puts "*** #{host}:#{port} connected"

    monitor = @selector.register(socket, :r)
    monitor.value = proc { read(socket) }
  end

  def read(socket)
    @counter ||= 0
    @counter += 1
    data = socket.read_nonblock(4096)
    response = {}
    response[:time] = Time.now
    response[:command] = data
    response[:session_counter] = @counter
    puts response
    json = response.to_json rescue ""
    socket.write_nonblock(json)
  rescue EOFError
    _, port, host = socket.peeraddr
    puts "*** #{host}:#{port} disconnected"

    @selector.deregister(socket)
    socket.close
  end
end

EchoServer.new("0.0.0.0", 8082).run if $PROGRAM_NAME == __FILE__
