# app/graphql/github_queries.rb

module GithubQueries
  PR_QUERY = GitHubGraphQL::Client.parse <<-'GRAPHQL'
    query($query: String!, $count: Int!) {
      search(query: $query, type: ISSUE, first: $count) {
        nodes {
          ... on PullRequest {
            number
            title
            url
            mergedAt
            additions
            deletions
            changedFiles
            author {
              login
            }
            repository {
              nameWithOwner
            }
          }
        }
      }
    }
  GRAPHQL
end