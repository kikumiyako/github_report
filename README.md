# README

## Setup
- Create your Personal access tokens (classic)
  - check these options below
    - Full control of private repositories
    - Read org and team membership, read org projects
- Create a ".env" file in the project root.\
```
OWNER=[account name]
REPO=[repository name]
GITHUB_TOKEN=[Personal access tokens (classic)]
```

## CSV download URL
http://localhost:3000/github_reports/index.csv

## How to check the rate_limit of the GitHub Api
curl -I -H "Authorization: token [GITHUB_TOKEN]" https://api.github.com/rate_limit
