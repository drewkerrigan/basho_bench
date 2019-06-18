FROM registry.sofi.com/sofi-alpine-elixir-v1_8_1:master
MAINTAINER dev@sofi.org

# Setup Application Release
USER root

# Install OS Packages
RUN set -xe \
  && apk update \
  && apk --no-cache add openssh-client R \
  && rm -rf /var/cache/apk/*

# Application User Setup
ADD . /home/elixir

# Switch User
WORKDIR /home/elixir
RUN chown -R elixir:elixir .
USER elixir

RUN set -xe \
  && ./rebar3 escriptize \
  && ln -s ./_build/default/bin/basho_bench \
  && chown -R elixir:elixir /usr/lib/R

CMD sleep 10000000000000000
