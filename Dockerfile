FROM ruby:2.3.4

RUN apt-get update -qq
RUN apt-get install -y locales
RUN locale-gen ru_RU.UTF-8 && update-locale
ENV LANG=ru_RU.UTF-8

MAINTAINER oganer@gmail.com
RUN apt-get update -qq && apt-get install -y \
	build-essential nodejs vim
RUN mkdir /app
WORKDIR /app
COPY . /app
RUN gem install nio4r celluloid celluloid-io byebug
EXPOSE 8082
CMD ruby ./ping_pong3.rb
