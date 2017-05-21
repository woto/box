#!/usr/bin/env ruby
# frozen_string_literal: true

require 'celluloid/debug'
require 'celluloid/current'
require 'celluloid/io'
require 'json'

require File.expand_path('config/environment', File.dirname(__FILE__))

class CableServer
  include Celluloid::IO
  include Celluloid::Notifications
  include Celluloid::Internals::Logger
  finalizer :finalize

  def initialize(host, port)
    info "*** Starting CableServer on #{host}:#{port}"
    # Since we included Celluloid::IO, we're actually making a
    # Celluloid::IO::TCPServer here
    @server = TCPServer.new(host, port)
    async.run
  end

  def finalize
    @server.close if @server
  end

  def run
    loop { async.handle_connection @server.accept }
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    info "*** Received connection on CableServer from #{host}:#{port}"
    loop do
      read = socket.readpartial(4096)
      json = JSON.parse(read)
      publish "push_to_device", json
    end
  rescue EOFError
    info "*** #{host}:#{port} disconnected from CableServer"
    socket.close
  end
end

class DeviceServer
  include Celluloid::IO
  include Celluloid::Notifications
  include Celluloid::Internals::Logger
  finalizer :finalize

  def initialize(host, port)
    @sockets = []
    subscribe "push_to_device", :push_to_device
    info "*** Starting DeviceServer on #{host}:#{port}"
    # Since we included Celluloid::IO, we're actually making a
    # Celluloid::IO::TCPServer here
    @server = TCPServer.new(host, port)
    async.run
  end

  def finalize
    @server.close if @server
  end

  def push_to_device(topic, hash)
    string = hash.to_json
    info "#{topic} #{string}"
    @sockets.each do |socket:, id:|
      if hash['id'] == id
        begin
          socket.write string.encode('CP1251')
        rescue IOError => e
          info e.inspect
          @sockets.delete @sockets.find { |s| s[:socket] == socket }
        end
      end
    end
  end

  def run
    loop { async.handle_connection @server.accept }
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    info "*** Received connection on DeviceServer from #{host}:#{port}"
    @sockets << {socket: socket, id: nil}

    loop do
      read = socket.readpartial(4096)
      socket.write "OK: #{read}"

      info read
      info read.bytes

      begin
        json = JSON.parse(read.force_encoding('CP1251').encode('UTF-8'))
        socket_hash = @sockets.find { |s| s[:socket] == socket }
        socket_hash[:id] = json["id"]
      rescue TypeError, NoMethodError, ArgumentError, JSON::ParserError => e
        raise ApplicationError.new(e.inspect)
      end

      InMessageJob.perform_later json

    end
  rescue EOFError, Errno::ETIMEDOUT, Errno::ECONNRESET, ApplicationError => e
    info e.inspect
    info "*** #{host}:#{port} disconnected from DeviceServer"
    socket.close
  end
end

class ApplicationError < StandardError; end

device_server = DeviceServer.new("0.0.0.0", 8084)
cable_server = CableServer.new("0.0.0.0", 8085)
trap("INT") { device_server.terminate; exit }
trap("INT") { cable_server.terminate; exit }
sleep

#NOTE
# subscribe "example_write_by_instance_method", :new_message
# subscribe "example_write_by_class_method", :new_message
# Celluloid::Notifications.publish "example_write_by_class_method", read
# publish "example_write_by_instance_method", read
