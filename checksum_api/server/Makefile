.PHONY: test

get-deps:
	mix deps.get

test:
	mix test

start-dev-server:
	mix phx.server

start-prod-server:
	MIX_ENV=prod mix release
	PORT=$(PORT) _build/prod/rel/checksum/bin/checksum start

stop-prod-server:
	_build/prod/rel/checksum/bin/checksum stop
