FROM hexpm/elixir:1.16.0-erlang-26.2.1-alpine-3.18.4

WORKDIR /opt/app
RUN apk add --no-cache curl bash alpine-sdk python3 py3-pip postgresql-client
RUN apk add --no-cache --update --virtual=build gcc musl-dev python3-dev libffi-dev openssl-dev cargo make
RUN pip3 install --no-cache-dir --prefer-binary azure-cli
RUN apk del build

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile minimal -y

SHELL ["/bin/bash", "-c"]

COPY . /opt/app/

ENV MIX_ENV=test

RUN mix deps.get
RUN source $HOME/.cargo/env && mix compile
