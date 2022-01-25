# GitHub Ring

> To rule them all, blablabla

Simple tool to warn you if your repository configuration is drifting from your expectations.
Useful mainly for organizations having lots of repositories.

## Run locally

You'll need to install the [gh cli tool](https://cli.github.com/) and authenticate.
Then, you're ready to go as in:

```bash
./main.sh
```

You might want to customize the repository query and the list of the expected values.
To do so, pass the environment variables `QUERY_STRING` and `EXPECTED_VALUES`.
Check the source code for examples.

## Run as GitHub action

First, you'll need a [PAT](https://github.com/settings/tokens) with the scopes `repo` and `read:org`, for a user with administrative access to the repositories you're interested in.

Then, create a repository for this action.
You'll need to save the token in action secrets (`https://github.com/___/___/settings/secrets/actions`), for example as `GH_RING_TOKEN`.
You can reuse an existing repository, but you have to be positive about giving away that PAT to the running Actions there.

Then, add `.github/workflows/gh-ring.yml`. Here's an example:

```yaml
name: GitHub Ring

on:
  workflow_dispatch:
  schedule:
    - cron: "7 9 * * 1" # every monday at 9:07 UTC

jobs:
  github-ring:
    name: GitHub Ring
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2 # This is necessary if you wish to user the {owner} placeholder is the query string (the default)
      - name: Run GitHub Ring
        uses: serl/github-ring@master
        env:
          GITHUB_TOKEN: ${{ secrets.GH_RING_TOKEN }}

  github-ring-custom-query-and-values:
    name: GitHub Ring with custom query and expected values
    runs-on: ubuntu-latest
    steps:
      - name: Run GitHub Ring
        uses: serl/github-ring@master
        env:
          GITHUB_TOKEN: ${{ secrets.GH_RING_TOKEN }}
        with:
          query-string: "user:example-org archived:false is:public example-repo"
          expected-values: |
            {
              "hasWikiEnabled": true,
              "hasIssuesEnabled" : true,
              "hasProjectsEnabled": false,
              "mergeCommitAllowed": true,
              "defaultBranchRef.branchProtectionRule.requiredApprovingReviewCount": 3,
            }

```
