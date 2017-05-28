FROM ruby:2.3.4
MAINTAINER oganer@gmail.com

# locales
RUN apt-get update -qq
RUN apt-get install -y locales
RUN locale-gen ru_RU.UTF-8 && update-locale
ENV LANG=ru_RU.UTF-8

RUN apt-get update -qq && apt-get install -y \
	apt-transport-https build-essential curl wget vim

# nodejs
RUN curl -sL https://deb.nodesource.com/setup_7.x | bash -
RUN apt-get install -y nodejs

# yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y yarn

RUN mkdir /app
WORKDIR /app
COPY . /app
RUN bundle install
CMD rake db:create && \
    rake db:migrate && \
    ./bin/rails s -p 8083 -b 0.0.0.0
