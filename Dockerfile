FROM registry.sofi.com/sofi-alpine-elixir-v1_8_1:master
MAINTAINER dev@sofi.org

# Setup Application Release
USER root

# Install OS Packages
RUN set -xe \
  && apk --no-cache add openssh-client \
  && rm -rf /var/cache/apk/*

# Application User Setup
ADD . /home/elixir

# Switch User
WORKDIR /home/elixir
RUN chown -R elixir:elixir .
USER elixir

CMD sleep 10000000000000000
