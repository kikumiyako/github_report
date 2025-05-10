require 'csv'

class GithubReportsController < ApplicationController

  def index
    pr_file_changes=  []

    begin
      fetcher = GithubRestPrFetcher.new(
        owner: "diggle-jp",
        repo: "cabernet",
        token: ENV["GITHUB_TOKEN"],
        per_page: 100,
        max_pages: 61
      )
      # データ取得
      pr_file_changes = fetcher.fetch_csv
    rescue => e
      Rails.logger.error "エラー発生: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")

      # 何も取得できていないならエラー画面にする
      if pr_file_changes.empty?
        raise e
      end
    end
    # CSV出力
    respond_to do |format|
      format.csv do
        send_data generate_csv(pr_file_changes),
                  filename: "github_pr_file_changes_#{Time.now}.csv"
      end
    end
  end

  def generate_csv(entries)
    CSV.generate(headers: true) do |csv|
      csv << %w[pr_number title merged_at file_path additions deletions]

      entries.each do |entry|
        csv << [
          entry[:pr_number],
          entry[:title],
          entry[:merged_at].strftime('%Y-%m-%d'),
          entry[:path],
          entry[:additions],
          entry[:deletions]
        ]
      end
    end
  end

  # def index
  #   fetcher = GithubPrFileFetcher.new(
  #     owner: "diggle-jp", # あなたの org またはユーザー
  #     repo: "cabernet", # リポジトリ名
  #     count: 100
  #   )
  #   @file_summary = fetcher.fetch
  #   respond_to do |format|
  #     format.html
  #     format.csv do
  #       send_data generate_csv(@file_summary),
  #                 filename: "github_file_change_summary_#{Time.zone.today}.csv"
  #     end
  #   end
  # end
  #
  # require 'csv'
  #
  # def generate_csv(data)
  #   CSV.generate(headers: true) do |csv|
  #     max_prs = data.map { |row| row[:pr_infos].size }.max || 0
  #     header = ['path', 'count', 'last_merged_at']
  #     max_prs.times { |i| header << "pr#{i + 1}" }
  #     csv << header
  #
  #     data.each do |row|
  #       line = [
  #         row[:path],
  #         row[:count],
  #         row[:last_merged_at].strftime('%Y-%m-%d')
  #       ]
  #
  #       row[:pr_infos].each do |pr|
  #         line << "##{pr[:number]}: #{pr[:title]} (#{pr[:merged_at].strftime('%Y-%m-%d')})"
  #       end
  #
  #       csv << line
  #     end
  #   end
  # end

  # def index
  #   @pulls = GithubPullRequestService.new(
  #     owner: "diggle-jp",
  #     repo: "cabernet",
  #     author: "kikumiyako",
  #     count: 10 # fetch count
  #   ).fetch
  # end
end
