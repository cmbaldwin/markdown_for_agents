# frozen_string_literal: true

module MarkdownForAgents
  class Railtie < ::Rails::Railtie
    initializer "markdown_for_agents.middleware" do |app|
      if ENV.key?("MARKDOWN_FOR_AGENTS_CONVERT")
        MarkdownForAgents.convert = ENV["MARKDOWN_FOR_AGENTS_CONVERT"] == "1"
      elsif MarkdownForAgents.convert.nil?
        MarkdownForAgents.convert = !Rails.env.production?
      end

      app.middleware.use MarkdownForAgents::Middleware
    end
  end
end
