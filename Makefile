.PHONY: setup dev build publish publish-dry deps test clean-entra docs docs-serve

setup: deps
	cd microsoft_graph && mix compile
	cd demo && mix compile

deps:
	cd microsoft_graph && mix deps.get
	cd demo && mix deps.get

dev:
	cd demo && iex -S mix

build:
	cd microsoft_graph && mix hex.build

publish:
	cd microsoft_graph && mix hex.publish

publish-dry:
	cd microsoft_graph && mix hex.publish --dry-run

test:
	cd microsoft_graph && mix test

docs:
	cd microsoft_graph && mix docs

docs-serve: docs
	npx five-server microsoft_graph/doc --port 5555

clean-entra:
	cd microsoft_graph && mix graph.cleanup
