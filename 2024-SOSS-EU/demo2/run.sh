#!/bin/bash

. ../demo-magic.sh

DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
TYPE_SPEED=30

IMAGE="quay.io/konflux-ci/ec-golden-image:latest"
GIT_REPO=enterprise-contract/golden-container
GIT_SHA=${GIT_SHA:-$(curl -s "https://api.github.com/repos/${GIT_REPO}/commits?per_page=1" | jq -r '.[0].sha')}

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

clear

pe "jq . snapshot.json"
pe "ec validate image --images snapshot.json --policy github.com/enterprise-contract/config//default --public-key public.key --ignore-rekor --show-successes"
pe "curl -sSl https://raw.githubusercontent.com/enterprise-contract/config/main/default/policy.yaml | yq ."

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
}' "${IMAGE}" "miscreant/mischief" "cafebabe" > snapshot.json

pe "jq . snapshot.json"
pe 'ec validate image --images snapshot.json --policy github.com/enterprise-contract/config//default --public-key public.key --ignore-rekor --output text --output attestation=attestation.json'
pe "jq -s '.[0].predicate.materials[] | select(.uri | startswith(\"git+\"))' attestation.json"
echo https://github.com/enterprise-contract/ec-policies/blob/main/policy/release/slsa_source_correlated.rego
