#!/usr/bin/env bash
set -e

default_expected_values='{
  "hasWikiEnabled": false,
  "hasIssuesEnabled": false,
  "hasProjectsEnabled": false,
  "mergeCommitAllowed": false,
  "rebaseMergeAllowed": false,
  "squashMergeAllowed": true,
  "autoMergeAllowed": true,
  "deleteBranchOnMerge": true,
  "defaultBranchRef.branchProtectionRule.requiresApprovingReviews": true,
  "defaultBranchRef.branchProtectionRule.requiredApprovingReviewCount": 1,
  "defaultBranchRef.branchProtectionRule.requiresStatusChecks": true,
  "defaultBranchRef.branchProtectionRule.requiresStrictStatusChecks": true,
  "defaultBranchRef.branchProtectionRule.requiresLinearHistory": true,
  "defaultBranchRef.branchProtectionRule.allowsForcePushes": false,
  "defaultBranchRef.branchProtectionRule.allowsDeletions": false
}'

: "${QUERY_STRING:="user:{owner} archived:false is:public"}"
: "${EXPECTED_VALUES:=$default_expected_values}"


log() {
  echo "$@" >&2
}

box_seq() {
  # https://en.wikipedia.org/wiki/Box-drawing_character#Unix,_CP/M,_BBS
  echo -e "\e(0$*\e(B"
}
color_seq() {
  echo -e "\e[$*m"
}

dep_check() {
  for cmd in gh jq base64; do
    if ! command -v $cmd >/dev/null; then
      log "$cmd is required"
      return 1
    fi
  done
  gh auth status || return
}

fetch_data() {
  # shellcheck disable=SC2016
  query='query ($queryString: String!, $numberRepos: Int = 100, $endCursor: String) {
    search(query: $queryString, type: REPOSITORY, first: $numberRepos, after: $endCursor) {
      edges {
        node {
          ... on Repository {
            name
            hasWikiEnabled
            hasIssuesEnabled
            hasProjectsEnabled
            mergeCommitAllowed
            rebaseMergeAllowed
            squashMergeAllowed
            autoMergeAllowed
            deleteBranchOnMerge
            defaultBranchRef {
              name
              branchProtectionRule {
                requiresApprovingReviews
                requiredApprovingReviewCount
                requiresStatusChecks
                requiresStrictStatusChecks
                requiredStatusCheckContexts
                requiresLinearHistory
                allowsForcePushes
                allowsDeletions
              }
            }
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }'

  log "Retrieving repository data"
  gh api graphql --paginate -F queryString="$QUERY_STRING" -f query="$query" | jq '.data.search.edges[].node' | jq -s
}

jq_data() {
  local data="$1"
  shift
  echo "$data" | jq -r "$@"
}

process_repo() {
  local repo_data="$1"

  log "$(box_seq lq) $(color_seq '34;1')$(jq_data "$repo_data" .name)$(color_seq 0)"

  for key in $(jq_data "$EXPECTED_VALUES" 'keys_unsorted[]'); do
    value=$(jq_data "$repo_data" ".$key")
    expected_value=$(jq_data "$EXPECTED_VALUES" ".\"$key\"")
    [[ $value == "$expected_value" ]] && continue

    log "$(box_seq x)  $(color_seq 33)$key$(color_seq 0) is $(color_seq 31)$value$(color_seq 0) instead of $(color_seq '32;1')$expected_value$(color_seq 0)"
  done

  required_checks="$(jq_data "$repo_data" .defaultBranchRef.branchProtectionRule.requiredStatusCheckContexts)"
  if [[ $required_checks == null ]] || [[ $required_checks == '[]' ]]; then
    log "$(box_seq x)  $(color_seq 31)No required checks for default branch$(color_seq 0)"
  fi
}

main() {
  dep_check

  local data
  data="$(fetch_data)"
  count="$(jq_data "$data" length)"

  if [[ $count -eq 0 ]]; then
    log "No repositories found"
    return 1
  fi

  log "Found $count repositories"

  for row in $(jq_data "$data" '.[] | @base64'); do
    process_repo "$(echo "$row" | base64 --decode)"
  done
}

main
