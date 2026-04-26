SHELL := /usr/bin/env bash

INPUT ?= examples/adventure.md
OUTPUT ?= dist/adventure.pdf

.PHONY: build docker-build clean

build:
	./scripts/build.sh $(INPUT) $(OUTPUT)

docker-build:
	./scripts/docker-build.sh $(INPUT) $(OUTPUT)

clean:
	rm -rf dist/*.pdf dist/*.tex
