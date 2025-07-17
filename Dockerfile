FROM elixir:1.16-slim

RUN apt-get update && apt-get install -y build-essential git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

COPY . .

RUN mix deps.get --only prod && \
	mix deps.compile && \
	mix compile && \
	mix release

EXPOSE 4000

CMD ["_build/prod/rel/yumegatari/bin/yumegatari", "start"]
