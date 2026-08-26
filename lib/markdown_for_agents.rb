# frozen_string_literal: true

require_relative "markdown_for_agents/version"
require_relative "markdown_for_agents/middleware"

module MarkdownForAgents
  class << self
    attr_writer :convert, :max_bytes, :skip_paths

    def convert?
      @convert == true
    end

    def convert
      @convert
    end

    def max_bytes
      @max_bytes ||= 2_097_152
    end

    def skip_paths
      @skip_paths ||= Middleware::SKIP_PATHS.dup
    end
  end
end

require_relative "markdown_for_agents/railtie" if defined?(Rails::Railtie)
