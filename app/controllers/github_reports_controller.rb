require 'csv'

class GithubReportsController < ApplicationController

  def index
    pr_file_changes=  []

    begin
      fetcher = GithubRestPrFetcher.new(
        owner: ENV["OWNER"],
        repo: ENV["REPO"],
        token: ENV["GITHUB_TOKEN"],
        per_page: 3,
        max_pages: 1
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

end
