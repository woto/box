#!/usr/bin/env ruby
# frozen_string_literal: true

require 'celluloid/debug'
require 'celluloid/current'
require 'celluloid/io'
require 'json'

require File.expand_path('config/environment', File.join(File.dirname(__FILE__), '..'))

module Identificator
  attr_accessor :sender
end

class CelluloidServer
  include Celluloid::IO
  include Celluloid::Notifications
  include Celluloid::Internals::Logger
  finalizer :finalize

  def initialize(host, port)
    @sockets = []
    @mutex = Mutex.new
    info "*** Starting CelluloidServer on #{host}:#{port}"
    # Since we included Celluloid::IO, we're actually making a
    # Celluloid::IO::TCPServer here
    @server = TCPServer.new(host, port)
    async.run
  end

  def finalize
    @server.close if @server
  end

  def push_to_device(hash)
    string = hash.to_json
    @mutex.synchronize do
      @sockets.each do |socket|
        if socket.sender == hash['receiver']
          begin
            socket.write string.encode('CP1251')
          rescue IOError => e
            info e.inspect
            @sockets.delete socket
          end
        end
      end
    end
  end

  def run
    loop { async.handle_connection @server.accept }
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    info "*** Received connection on CelluloidServer from #{host}:#{port}"
    socket.extend Identificator
    @mutex.synchronize do
      @sockets << socket
    end
    info "@sockets size #{@sockets.size}"

    loop do
      read = socket.readpartial(4096)
      socket.write "OK: #{read}"

      info read
      info read.bytes

      hash = JSON.parse(read.force_encoding('CP1251').encode('UTF-8'))
      if hash["sender"]
        socket.sender = hash["sender"]
        InMessageJob.perform_later hash
      end
      if hash["receiver"]
        push_to_device hash
      end
    end
  rescue EOFError, TypeError, NoMethodError, ArgumentError, JSON::ParserError, Errno::ETIMEDOUT, Errno::ECONNRESET, ApplicationError => e
    info e.inspect
    info e.backtrace
    info "*** #{host}:#{port} disconnected from CelluloidServer"
    socket.close
    @mutex.synchronize do
      needle = @sockets.find { |haystack| haystack == socket }
      @sockets.delete needle
    end
  end
end

class ApplicationError < StandardError; end

celluloid_server = CelluloidServer.new("0.0.0.0", 8084)
trap("INT") { celluloid_server.terminate; exit }
sleep

# NOTE
# subscribe "example_write_by_instance_method", :new_message
# subscribe "example_write_by_class_method", :new_message
# Celluloid::Notifications.publish "example_write_by_class_method", read
# publish "example_write_by_instance_method", read
