.PHONY: dev db stop compile setup test


dev:
	iex -S mix


db:
	docker compose up -d


stop:
	docker compose down

compile:
	mix compile
	mix escript.build

setup:
	mix ecto.setup
	mix ecto.setup.test

test:
	MIX_ENV=test mix coveralls




