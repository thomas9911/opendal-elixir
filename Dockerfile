FROM hexpm/elixir:1.16.0-erlang-26.2.1-alpine-3.18.4

WORKDIR /opt/app
RUN apk add curl bash alpine-sdk
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile minimal -y

SHELL ["/bin/bash", "-c"]

COPY . /opt/app/

ENV MIX_ENV=test

RUN mix deps.get
RUN source $HOME/.cargo/env && mix compile
