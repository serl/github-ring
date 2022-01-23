#!/usr/bin/env bash
set -e

log() {
  echo "$@" >&2
}

dep_check() {
  if ! command -v jq >/dev/null; then
    log "jq is required"
    return 1
  fi
  gh auth status || return
}

data_cache=
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
                requiredApprovingReviewCount
                requiresApprovingReviews
                requiresStatusChecks
                requiresStrictStatusChecks
                requiredStatusCheckContexts
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
  data_cache="$(gh api graphql --paginate -F queryString='user:{owner} archived:false' -f query="$query" | jq '.data.search.edges[].node' | jq -s)"
}

jq_data() {
  echo "$data_cache" | jq "$@"
}


main() {
  dep_check

  fetch_data
  count="$(jq_data length)"

  if [[ $count -eq 0 ]]; then
    echo "No repositories found"
    return 1
  fi

  echo "Found $count repositories"

  # jq_data '.[].name'
}

main
