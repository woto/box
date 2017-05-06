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
      puts read.bytes
      response = {}
      response[:time] = Time.now
      response[:bytes] = read.bytes
      response[:string] = read.force_encoding(Encoding::CP1251)
      response[:counter] = actor.increment
      begin
        json = response.to_json
      rescue StandardError => e
        json = e.message
      end
      socket.write json
    end
  rescue EOFError, Errno::ECONNRESET
    puts "*** #{host}:#{port} disconnected"
    actor.terminate
    socket.close
  end
end

supervisor = EchoServer.new("0.0.0.0", 8082)
trap("INT") { supervisor.terminate; exit }
sleep
