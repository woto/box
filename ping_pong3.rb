require 'celluloid/current'
require 'celluloid/io'
require 'json'

SUCCESS = 'success'
FAILURE = 'failure'
PENDING = 'pending'

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

  def send_message(result, socket, counter, bytes, message, encoding)
    raise 'result should be a fixed string' unless [SUCCESS, PENDING, FAILURE].include?(result)
    raise 'counter should be an integer' unless counter.is_a?(Integer)
    raise 'message should be a string' unless message.is_a?(String)
    response = {result: result, message: message}
    response[:time] = Time.now
    response[:bytes] = bytes
    response[:counter] = counter
    json = begin
      response.to_json
    rescue Encoding::UndefinedConversionError, JSON::GeneratorError => e
      error = "Generate error: #{SecureRandom.uuid}"
      puts error
      response[:message] = error
      response.to_json
    end
    socket.write json.encode(encoding)
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    puts "*** Received connection from #{host}:#{port}"
    actor = Counter.new

    loop do
      read = socket.readpartial(4096)
      counter = actor.increment
      puts read
      print read.bytes
      puts

      begin
        json = JSON.parse(read)
      rescue JSON::ParserError => e
        error = "Parse error: #{SecureRandom.uuid}"
        puts error
        send_message(FAILURE, socket, counter, read.bytes, error, 'Windows-1252')
        raise 'exit'
      end

      begin
        message = json['message'].force_encoding(json['encoding'])
      rescue TypeError, NoMethodError, ArgumentError => e
        error = "Encoding error: #{SecureRandom.uuid}"
        puts error
        send_message(FAILURE, socket, counter, read.bytes, error, 'Windows-1252')
        raise 'exit'
      end

      send_message(SUCCESS, socket, counter, read.bytes, message, json['encoding'])
    end
  rescue StandardError, EOFError, Errno::ECONNRESET => e
    puts e.message
    puts "*** #{host}:#{port} disconnected"
    actor.terminate
    socket.close
  end
end

supervisor = EchoServer.new("0.0.0.0", 8082)
trap("INT") { supervisor.terminate; exit }
sleep
