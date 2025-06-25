#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

image=$(podman build --quiet --file <(cat <<DOCKERFILE
FROM quay.io/conforma/cli:snapshot

USER 0

RUN rpm --quiet -i https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    rpm --quiet -i https://github.com/sigstore/cosign/releases/download/v2.4.0/cosign-2.4.0-1.x86_64.rpm && \
    microdnf install -y ncurses pv bat cowsay && \
    curl -sL -o /usr/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/bin/yq

DOCKERFILE
))

podman run -it --rm -v $(pwd):/demo:Z -w /demo --entrypoint=/bin/bash "${image}" -c '
clear

cowsay "Demo 1"
(cd demo1 && ./run.sh)

read && clear

cowsay "Demo 2"
(cd demo2 && ./run.sh)

read && clear

cowsay "Demo 3"
(cd demo3 && ./run.sh)

read && clear

cowsay "Thanks"

read
'
