require 'celluloid/current'
require 'celluloid/io'
require 'json'

class EchoServer
  include Celluloid::IO
  include Celluloid::Notifications
  include Celluloid::Internals::Logger

  finalizer :finalize

  def initialize(host, port)
    #subscribe "example_write_by_instance_method", :new_message
    #subscribe "example_write_by_class_method", :new_message

    puts "*** Starting echo server on #{host}:#{port}"

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
    puts "*** Received connection from #{host}:#{port}"
    loop do
      info "before_read"
      read = socket.readpartial(4096)
      info "after_read"
      socket.write "response: #{read}"
      #publish "example_write_by_instance_method", socket, read
      Celluloid::Notifications.publish "example_write_by_class_method", read
    end
  rescue EOFError
    puts "*** #{host}:#{port} disconnected"
    socket.close
  end
end

class Subscriber
  include Celluloid::IO
  include Celluloid::Notifications
  include Celluloid::Internals::Logger

  finalizer :finalize

  def initialize(host, port)
    subscribe "example_write_by_instance_method", :new_message
    subscribe "example_write_by_class_method", :new_message

    puts "*** Starting echo server on #{host}:#{port}"

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
    @socket = socket
    _, port, host = socket.peeraddr
    puts "*** Received connection from #{host}:#{port}"
    loop do
      info "before_read"
      read = socket.readpartial(4096)
      info "after_read"
      socket.write "response: #{read}"
      #publish "example_write_by_instance_method", socket, read
      #Celluloid::Notifications.publish "example_write_by_class_method", read
    end
  rescue EOFError
    puts "*** #{host}:#{port} disconnected"
    socket.close
  end

  def new_message(topic, data)
    info '!!!!!!!!!!!!!!!!!!!!!!'
    info "#{topic}: #{data}"
    @socket.write "response: #{data}"
  end
end

supervisor = EchoServer.new("127.0.0.1", 1234)
trap("INT") { supervisor.terminate; exit }

supervisor2 = Subscriber.new("127.0.0.1", 1235)
trap("INT") { supervisor2.terminate; exit }

sleep
