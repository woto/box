#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'
require 'json'

module EchoServer
  def post_init
    puts "-- someone connected to the echo server!"
    @counter = 0
  end

  def receive_data data
    @counter += 1
    response = {}
    response[:time] = Time.now
    response[:command] = data
    response[:session_counter] = @counter
    puts response
    send_data response.to_json
  end
end

EventMachine::run {
  EventMachine::start_server "0.0.0.0", 8081, EchoServer
  puts 'running echo server on 8081'
}
