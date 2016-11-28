FROM ruby:2.2.6
MAINTAINER oganer@gmail.com
RUN apt-get update -qq && apt-get install -y \
	build-essential nodejs
RUN mkdir /app
WORKDIR /app
COPY . /app
RUN gem install eventmachine
CMD ruby ping_pong.rb
