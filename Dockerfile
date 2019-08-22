FROM ruby:2.6.0

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle install --path vendor/cache --without test

COPY . .

ENTRYPOINT ["bundle", "exec", "./bin/exporter"]
