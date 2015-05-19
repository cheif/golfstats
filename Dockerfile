FROM ruby:2.1

WORKDIR /app
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install --without production

ADD . /app
