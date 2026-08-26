# frozen_string_literal: true

require_relative "lib/markdown_for_agents/version"

Gem::Specification.new do |spec|
  spec.name = "markdown_for_agents"
  spec.version = MarkdownForAgents::VERSION
  spec.authors = ["Cody Baldwin"]
  spec.email = ["codybaldwin@gmail.com"]
  spec.homepage = "https://github.com/cmbaldwin/markdown_for_agents"
  spec.summary = "Serve text/markdown to AI agents from the same HTML URLs"
  spec.description = "Rack middleware that stops Rails 8.1 from 406-ing " \
                     "Accept: text/markdown, and optionally converts HTML " \
                     "responses to markdown. Pair with Cloudflare Markdown " \
                     "for Agents (content_converter) in production."
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "MIT-LICENSE", "README.md"]
  end

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "rack", ">= 2.2"
  spec.add_dependency "reverse_markdown", ">= 2.0"
end
