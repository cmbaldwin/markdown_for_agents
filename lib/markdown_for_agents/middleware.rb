# frozen_string_literal: true

require "reverse_markdown"

module MarkdownForAgents
  class Middleware
    HTML_TYPE = %r{\Atext/html\b}i
    # Don't rewrite Accept on APIs/assets — those are not HTML documents.
    SKIP_REWRITE = [
      %r{\A/assets/},
      %r{\A/rails/},
      %r{\A/api/},
      %r{\A/mcp(?:/|\z)},
      %r{\A/cable\z},
      %r{\.json\z}
    ].freeze

    # Health endpoints must still have Accept rewritten (Rails 8.1 406s on
    # text/markdown) but should keep their native body, not markdown.
    SKIP_CONVERT = SKIP_REWRITE + [
      %r{\A/up\z},
      %r{\A/health(?:z|/|\z)}
    ].freeze

    SKIP_PATHS = SKIP_CONVERT

    def initialize(app)
      @app = app
    end

    def call(env)
      want = prefers_markdown?(env["HTTP_ACCEPT"])
      rewrite = want && !skip_rewrite?(env)
      env["HTTP_ACCEPT"] = "text/html" if rewrite

      status, headers, body = @app.call(env)
      return [status, headers, body] unless rewrite && MarkdownForAgents.convert?
      return [status, headers, body] unless html_success?(status, headers)
      return [status, headers, body] if skip_convert?(env)

      html = read_body(body)
      return [status, headers, body] if html.bytesize > MarkdownForAgents.max_bytes

      markdown = ReverseMarkdown.convert(html, github_flavored: true)
      headers = headers.dup
      header_set(headers, "content-type", "text/markdown; charset=utf-8")
      header_set(headers, "content-length", markdown.bytesize.to_s)
      merge_vary(headers)
      header_set(headers, "x-markdown-converter", "markdown_for_agents")
      drop_body_validators(headers)

      [status, headers, [markdown]]
    end

    private

    def skip_rewrite?(env)
      path = env["PATH_INFO"].to_s
      SKIP_REWRITE.any? { |re| path.match?(re) }
    end

    def skip_convert?(env)
      path = env["PATH_INFO"].to_s
      MarkdownForAgents.skip_paths.any? { |re| path.match?(re) }
    end

    def prefers_markdown?(accept)
      return false if accept.nil? || accept.strip.empty?

      ranges = parse_accept(accept)
      md_q, md_i = best(ranges, "text/markdown")
      return false if md_q.nil?

      html_q, html_i = best(ranges, "text/html")
      html_q ||= 0.0
      return true if md_q > html_q
      return false if md_q < html_q

      html_i.nil? || md_i < html_i
    end

    def parse_accept(header)
      i = -1
      header.split(",").map do |part|
        i += 1
        media, *params = part.split(";").map(&:strip)
        q = 1.0
        params.each { |p| q = $1.to_f if p =~ /\Aq=([\d.]+)\z/ }
        [media.downcase, q, i]
      end
    end

    def best(ranges, type)
      match = ranges.select { |t, q, _| t == type && q > 0 }
      return [nil, nil] if match.empty?

      top = match.max_by { |_, q, _| q }
      [top[1], top[2]]
    end

    def html_success?(status, headers)
      status.to_i.between?(200, 299) && header_get(headers, "content-type").to_s.match?(HTML_TYPE)
    end

    def read_body(body)
      buf = +""
      body.each { |part| buf << part }
      buf
    ensure
      body.close if body.respond_to?(:close)
    end

    def merge_vary(headers)
      existing = header_get(headers, "vary").to_s
      parts = existing.split(",").map { |s| s.strip }.reject(&:empty?)
      parts << "Accept" unless parts.any? { |p| p.casecmp("Accept").zero? }
      header_set(headers, "vary", parts.join(", "))
    end

    def drop_body_validators(headers)
      %w[etag last-modified content-encoding content-range transfer-encoding].each do |name|
        header_delete(headers, name)
      end
    end

    def header_get(headers, name)
      headers.each { |k, v| return v if k.to_s.downcase == name }
      nil
    end

    def header_set(headers, name, value)
      header_delete(headers, name)
      headers[name] = value
    end

    def header_delete(headers, name)
      headers.keys.select { |k| k.to_s.downcase == name }.each { |k| headers.delete(k) }
    end
  end
end
