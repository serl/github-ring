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
