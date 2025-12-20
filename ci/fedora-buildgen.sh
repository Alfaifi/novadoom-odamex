#!/usr/bin/env bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/

set -euo pipefail
IFS=$'\n\t'

set -x

docker build -t novadoom -f ci/fedora.Dockerfile .
docker run --rm novadoom
