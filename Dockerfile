FROM erlang:22.1.4-alpine

# Install OS Packages
RUN set -xe \
  && apk update \
  && apk --no-cache add openssh-client xvfb R R-dev curl make git bash g++ vim \
  && chown -R root:root /usr/lib/R \
  && rm -rf /var/cache/apk/*

# Application User Setup
ADD . /opt/basho-bench

# Switch User
WORKDIR /opt/basho-bench

RUN set -xe \
    && curl -fSL -o rebar3 "https://s3.amazonaws.com/rebar3-nightly/rebar3" \
    && chmod +x ./rebar3 \
    && ./rebar3 local install

RUN set -xe \
  && ./rebar3 escriptize \
  && Rscript --vanilla priv/common.r \
  && ln -s ./_build/default/bin/basho_bench

CMD sleep 10000000000000000
