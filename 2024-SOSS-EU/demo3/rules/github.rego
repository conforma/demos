#
# METADATA
# title: Restrictions on github origins
package custom

import rego.v1

# METADATA
# custom:
#   short_name: git_origin_restriction
deny contains result if {
	allowed_origin := data.rule_data__configuration__.allowed_github_origins		# e.g. "enterprise-contract"
	allowed_material_uri := sprintf("git+https://github.com/%s/", [allowed_origin])	# e.g. "git+https://github.com/enterprise-contract/"
	some attestation in input.attestations											# loop over all attestations provided in input
	found := [material |
		some material in attestation.statement.predicate.materials					# loop over all materials in an attestation
		startswith(material.uri, allowed_material_uri)								# collect a value if it contains URI hat starts with ...
	]
	count(found) == 0 # if we found none
	result := {
		"code": "custom.git_origin_restriction",
		"msg": sprintf("Source code did not originate from the %s GitHub organization", [allowed_origin]),
	}
}
