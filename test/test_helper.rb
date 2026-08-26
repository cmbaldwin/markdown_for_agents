# frozen_string_literal: true

require "minitest/autorun"
require "rack"
require "rack/mock"
require_relative "../lib/markdown_for_agents"

module MarkdownForAgents
  class TestCase < Minitest::Test
    def setup
      MarkdownForAgents.convert = true
      MarkdownForAgents.max_bytes = 2_097_152
      MarkdownForAgents.skip_paths = MarkdownForAgents::Middleware::SKIP_PATHS.dup
    end

    def teardown
      MarkdownForAgents.convert = nil
    end

    def html_app(status: 200, type: "text/html; charset=utf-8", body: "<html><body><h1>Hello</h1><p>World</p></body></html>", extra: {})
      lambda do |_env|
        [status, { "content-type" => type }.merge(extra), [body]]
      end
    end

    def request(app, path: "/", accept: "text/markdown", env: {})
      MarkdownForAgents::Middleware.new(app).call(
        Rack::MockRequest.env_for(path, { "HTTP_ACCEPT" => accept }.merge(env))
      )
    end
  end
end
