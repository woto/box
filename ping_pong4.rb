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
    subscribe "push_to_websocket", :push_to_websocket
    info "*** Starting CableServer on #{host}:#{port}"
    @server = TCPServer.new(host, port)
    async.run
  end

  def finalize
    @server.close if @server
  end

  def push_to_websocket(topic, data)
    info "#{topic}: #{data}"
    begin
      ActionCable.server.broadcast("a", data)
    rescue Encoding::UndefinedConversionError => e
      info e
    end
  end

  def run
    loop { async.handle_connection @server.accept }
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    info "*** Received connection on CableServer from #{host}:#{port}"
    loop do
      read = socket.readpartial(4096)
      publish "push_to_device", read
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
    @server = TCPServer.new(host, port)
    async.run
  end

  def finalize
    @server.close if @server
  end

  def push_to_device(topic, data)
    info "#{topic}: #{data}"
    @sockets.each do |socket|
      async.write_to_socket(socket, data)
    end
  end

  def run
    loop { async.handle_connection @server.accept }
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    info "*** Received connection on DeviceServer from #{host}:#{port}"
    @sockets << socket
    loop do
      read = socket.readpartial(4096)
      publish "push_to_websocket", read
    end
  rescue EOFError, Errno::ETIMEDOUT, Errno::ECONNRESET => e
    info "*** #{host}:#{port} disconnected from DeviceServer"
    socket.close
  end

  private

  def write_to_socket(socket, data)
    begin
      socket.write "#{data}"
    rescue IOError => e
      info "Rescued #{e}"
      @sockets.delete socket
    end
  end

end

device_supervisor = DeviceServer.new("0.0.0.0", 8084)
action_cable_supervisor = CableServer.new("0.0.0.0", 8085)
trap("INT") { device_supervisor.terminate; exit }
trap("INT") { action_cable_supervisor.terminate; exit }
sleep

#NOTE
# subscribe "example_write_by_instance_method", :new_message
# subscribe "example_write_by_class_method", :new_message
# Celluloid::Notifications.publish "example_write_by_class_method", read
# publish "example_write_by_instance_method", read
