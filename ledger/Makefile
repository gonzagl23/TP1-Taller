.PHONY: dev db stop compile


dev:
	iex -S mix


db:
	docker compose up -d


stop:
	docker compose down

compile:
	mix compile
	mix escript.build




