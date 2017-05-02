require 'celluloid/current'
require 'celluloid/io'
require 'json'

class Counter
  # This is all you have to do to turn any Ruby class into one which creates
  # Celluloid actors instead of normal objects
  include Celluloid

  # Now just define methods like you ordinarily would
  attr_reader :count

  def initialize
    @count = 0
  end

  def increment(n = 1)
    @count += n
  end
end

class EchoServer
  include Celluloid::IO
  finalizer :shutdown

  def initialize(host, port)
    puts "*** Starting echo server on #{host}:#{port}"

    # Since we included Celluloid::IO, we're actually making a
    # Celluloid::IO::TCPServer here
    @server = TCPServer.new(host, port)
    async.run
  end

  def shutdown
    @server.close if @server
  end

  def run
    loop { async.handle_connection @server.accept }
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    puts "*** Received connection from #{host}:#{port}"
    actor = Counter.new

    loop do
      read = socket.readpartial(4096)
      response = {}
      response[:time] = Time.now
      response[:command] = read.force_encoding('UTF-8')
      response[:session_counter] = actor.increment
      begin
        json = response.to_json
      rescue StandardError => e
        json = e.message
      end
      socket.write json
    end
  rescue EOFError
    puts "*** #{host}:#{port} disconnected"
    socket.close
    actor.terminate
  end
end

supervisor = EchoServer.new("0.0.0.0", 8082)
trap("INT") { supervisor.terminate; exit }
sleep
