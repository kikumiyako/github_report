# app/services/github_rest_pr_fetcher.rb
require 'net/http'
require 'json'

class GithubRestPrFetcher
  def initialize(owner:, repo:, token:, per_page: 100, max_pages: 5)
    @owner = owner
    @repo = repo
    @token = token
    @per_page = per_page
    @max_pages = max_pages
  end

  def fetch
    file_summary = {}

    page = 1
    while page <= @max_pages
      prs = fetch_prs(page)
      break if prs.empty?

      prs.each do |pr|
        next unless pr["merged_at"] # ← merged PRのみ対象

        files = fetch_pr_files(pr["number"])
        files.each do |file|
          path = file["filename"]

          file_summary[path] ||= { pr_infos: [] }

          file_summary[path][:pr_infos] << {
            number: pr["number"],
            title: pr["title"],
            merged_at: Time.parse(pr["merged_at"]),
            additions: file["additions"],
            deletions: file["deletions"]
          }
        end
      end

      page += 1
    end

    file_summary.map do |path, data|
      sorted = data[:pr_infos].sort_by { |info| -info[:merged_at].to_i }
      {
        path: path,
        pr_infos: sorted,
        last_merged_at: sorted.first[:merged_at]
      }
    end.sort_by { |e| -e[:last_merged_at].to_i }
  end

  def fetch_csv(flatten: false)
    result = []

    (42..@max_pages).each do |page|
      Rails.logger.info "Fetching PR list page #{page}..."
      prs = fetch_prs(page)
      break if prs.empty?

      count_pr = 0
      prs.each do |pr|
        count_pr += 1
        next unless pr["merged_at"]

        files = fetch_pr_files(pr["number"])
        Rails.logger.info "  Fetching PR #{count_pr}(files: #{files.count})/#{prs.count}..."
        files.each do |file|
          result << {
            pr_number: pr["number"],
            title: pr["title"],
            merged_at: Time.parse(pr["merged_at"]),
            path: file["filename"],
            additions: file["additions"],
            deletions: file["deletions"]
          }
        end
      end
    end

    result.sort_by! { |r| [-r[:merged_at].to_i, -r[:pr_number]] }
    result
  end

  private

  def fetch_prs(page)
    get_json("/repos/#{@owner}/#{@repo}/pulls?state=closed&base=master&per_page=#{@per_page}&page=#{page}")
  end

  def fetch_pr_files(pr_number)
    get_json("/repos/#{@owner}/#{@repo}/pulls/#{pr_number}/files")
  end

  def get_json(path)
    uri = URI("https://api.github.com#{path}")
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "token #{@token}"
    req['Accept'] = 'application/vnd.github+json'

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    raise "GitHub API error #{res.code}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end
end