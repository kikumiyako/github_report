# app/services/github_pull_request_service.rb

class GithubPullRequestService
  include GithubQueries

  def initialize(owner:, repo:, author:, count: 10)
    @owner = owner
    @repo = repo
    @author = author
    @count = count
  end

  def fetch
    q = "repo:#{@owner}/#{@repo} is:pr is:merged author:#{@author}"
    # q = "is:pr is:merged author:#{@author}"
    puts q

    response = GitHubGraphQL::Client.query(
      PR_QUERY,
      variables: { query: q, count: @count }
    )

    raise response.errors[:data].to_s if response.errors.any?

    puts response.data.search.nodes.inspect

    response.data.search.nodes.map do |pr|
      {
        number: pr.number,
        title: pr.title,
        url: pr.url,
        merged_at: pr.merged_at,
        additions: pr.additions,
        deletions: pr.deletions,
        changed_files: pr.changed_files,
        author: pr.author&.login,
        repo: pr.repository.name_with_owner
      }
    end
  end
end