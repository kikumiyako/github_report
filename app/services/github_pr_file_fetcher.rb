class GithubPrFileFetcher
  SEARCH_QUERY = GitHubGraphQL::Client.parse <<-'GRAPHQL'
    query($queryString: String!, $count: Int!) {
      search(query: $queryString, type: ISSUE, first: $count) {
        nodes {
          ... on PullRequest {
            number
            title
            mergedAt
            baseRefName
            author { login }
            files(first: 100) {
              nodes {
                path
              }
            }
          }
        }
      }
    }
  GRAPHQL

  PR_QUERY = GitHubGraphQL::Client.parse <<-'GRAPHQL'
    query($owner: String!, $repo: String!, $count: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequests(first: $count, states: MERGED, orderBy: {field: UPDATED_AT, direction: DESC}) {
          nodes {
            number
            title
            mergedAt
            additions
            deletions
            changedFiles
            author { login }
            files(first: 100) {
              nodes {
                path
              }
            }
          }
        }
      }
    }
  GRAPHQL

  def initialize(owner:, repo:, count: 50)
    @owner = owner
    @repo = repo
    @count = count
  end

  def fetch
    # response = GitHubGraphQL::Client.query(
    #   PR_QUERY,
    #   variables: {
    #     owner: @owner,
    #     repo: @repo,
    #     count: @count
    #   }
    # )
    query = "repo:#{@owner}/#{@repo} is:pr is:merged base:master"

    response = GitHubGraphQL::Client.query(SEARCH_QUERY, variables: {
      queryString: query,
      count: @count
    })

    # summarize_pr_query(response)
    summarize_search(response)
  end

  def summarize_search(response)
    summary = {}

    pr_nodes = response.data.to_h.dig("search", "nodes") || []

    pr_nodes.each do |pr|
      pr_number = pr["number"]
      pr_title  = pr["title"]
      merged_at = Time.parse(pr["mergedAt"].to_s)
      files     = pr.dig("files", "nodes") || []

      files.each do |file|
        path = file["path"]

        summary[path] ||= {
          pr_infos: [],
          count: 0
        }

        summary[path][:pr_infos] << {
          number: pr_number,
          title: pr_title,
          merged_at: merged_at
        }
        summary[path][:count] += 1
      end
    end

    # 整形して返す（mergedAt降順でソート）
    summary.map do |path, data|
      sorted_infos = data[:pr_infos].sort_by { |info| -info[:merged_at].to_i }
      {
        path: path,
        count: data[:count],
        pr_infos: sorted_infos,
        last_merged_at: sorted_infos.first[:merged_at]
      }
    end.sort_by { |entry| -entry[:last_merged_at].to_i }
  end

  def summarize_pr_query(response)
    pr_nodes = response.data.to_h.dig("repository", "pullRequests", "nodes") || []

    summary = {}
    pr_nodes.each do |pr|  # ← ここは mergedAt の降順
      pr_number = pr["number"]
      pr_title  = pr["title"]
      merged_at = Time.parse(pr["mergedAt"].to_s)
      files     = pr.dig("files", "nodes") || []

      files_count = files.size
      next if files_count.zero?

      files.each do |file|
        path = file["path"]
        if summary.has_key?(path)
          summary[path][:count] += 1
          summary[path][:last_merged_at] << merged_at
        else
          # ファイルが初めて登場したときだけ、merged_at と PR 情報を保存
          summary[path] ||= {
            count: 1,
            last_merged_at: [merged_at],
            pr_titles: ["##{pr_number}: #{pr_title}"]
          }
        end

        # # タイトルは重複しないように追加（必要なら）
        # unless summary[path][:pr_titles].include?("##{pr_number}: #{pr_title}")
        #   summary[path][:pr_titles] << "##{pr_number}: #{pr_title}"
        # end
      end
    end

    summary.map do |path, data|
      {
        path: path,
        last_merged_at: data[:last_merged_at],
        count: data[:count],
        # additions: data[:additions],
        # deletions: data[:deletions],
        pr_titles: data[:pr_titles]
      }
    # end.sort_by { |entry| -entry[:last_merged_at].to_i }
    end
  end

  # def scoring
  #   @file_scores = @file_changes.group_by { |f| f[:path] }.map do |path, changes|
  #     total_changes = changes.size
  #     total_lines = changes.sum { |c| c[:additions].to_i + c[:deletions].to_i }
  #
  #     last_updated_at = changes.map { |c| Time.parse(c[:merged_at].to_s) }.max
  #     days_ago = (Time.zone.now.to_date - last_updated_at.to_date).to_i
  #
  #     recency_score =
  #       if days_ago <= 30
  #         5
  #       elsif days_ago <= 90
  #         3
  #       elsif days_ago <= 180
  #         1
  #       else
  #         0
  #       end
  #
  #     score = (total_changes * 1.5) + (total_lines * 0.3) + (recency_score * 2.0)
  #
  #     {
  #       path: path,
  #       score: score.round(2),
  #       changes: "(#{total_changes} * 1.5)",
  #       lines: "(#{total_lines} * 0.3)",
  #       recency: "(#{recency_score} * 2.0)",
  #       last_updated_at: last_updated_at
  #     }
  #   end.sort_by { |entry| -entry[:score] }
  # end
end