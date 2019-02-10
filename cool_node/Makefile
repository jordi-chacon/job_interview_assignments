.PHONY: test

get-deps:
	mix deps.get

build:
	MIX_ENV=prod mix release

test:
	mix test

start-local-node:
	echo "'127.0.0.1'." > _build/prod/rel/cool_node/.hosts.erlang
	MIX_ENV=prod REPLACE_OS_VARS=true COOKIE=oreo NODE_NAME=$(NAME) _build/prod/rel/cool_node/bin/cool_node start

stop-local-node:
	MIX_ENV=prod REPLACE_OS_VARS=true COOKIE=oreo NODE_NAME=$(NAME) _build/prod/rel/cool_node/bin/cool_node stop
