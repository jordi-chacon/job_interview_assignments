# Elixir server

Uses Phoenix to serve the HTTP API and a GenServer called `NumbersServer` to keep the state.

## Dependencies

- Elixir 1.8 or higher

## Start dev server

```
make get-deps
make start-dev-server
```

## Run tests

```
make test
```

## Start prod server

```
make start-prod-server PORT=4000
```

## Stop prod server

```
make stop-prod-server
```
