FROM ruby:2.3.4
MAINTAINER oganer@gmail.com
RUN apt-get update -qq && apt-get install -y \
	build-essential nodejs vim
RUN mkdir /app
WORKDIR /app
COPY . /app
RUN gem install nio4r celluloid celluloid-io byebug
EXPOSE 8082
CMD ruby ./ping_pong3.rb
