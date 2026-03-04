.PHONY: setup dev build publish deps test clean-entra

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

test:
	cd microsoft_graph && mix test

clean-entra:
	cd microsoft_graph && mix graph.cleanup
