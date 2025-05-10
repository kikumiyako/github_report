# config/initializers/github_graphql.rb

require 'graphql/client'
require 'graphql/client/http'

GITHUB_TOKEN = ENV['GITHUB_TOKEN']

module GitHubGraphQL
  HTTP = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
    def headers(_context)
      {
        "Authorization" => "Bearer #{GITHUB_TOKEN}"
      }
    end
  end

  Schema = GraphQL::Client.load_schema(HTTP)
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end