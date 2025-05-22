#!/bin/bash
. ../demo-magic.sh

DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
TYPE_SPEED=30
export BAT_THEME=GitHub

IMAGE="quay.io/konflux-ci/ec-golden-image:latest"
GIT_REPO=conforma/golden-container
GIT_SHA=${GIT_SHA:-$(curl -s "https://api.github.com/repos/${GIT_REPO}/commits?per_page=1" | jq -r '.[0].sha')}

cat > policy.yaml << EOF
---
name: Custom
publicKey: |
  -----BEGIN PUBLIC KEY-----
  MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEZP/0htjhVt2y0ohjgtIIgICOtQtA
  naYJRuLprwIv6FDhZ5yFjYUEtsmoNcW7rx2KM6FOXGsCX3BNc7qhHELT+g==
  -----END PUBLIC KEY-----
sources:
  - policy:
      - ./rules
    ruleData:
      allowed_github_origins: conforma
EOF

printf '{
  "components": [
    {
      "name": "golden-container",
      "containerImage": "%s",
      "source": {
        "git": {
          "url": "https://github.com/%s",
          "revision": "%s"
        }
      }
    }
  ]
}' "${IMAGE}" "${GIT_REPO}" "${GIT_SHA}" > snapshot.json

pe "yq . policy.yaml"
pe "bat rules/github.rego"
pe "ec validate image --image ${IMAGE} --policy policy.yaml --info --show-successes --ignore-rekor"
pe "yq -i e '.sources[0].ruleData.allowed_github_origins |= \"acme-org\"' policy.yaml"
pe "yq . policy.yaml"
pe "ec validate image --image ${IMAGE} --policy policy.yaml --info --show-successes --ignore-rekor"
