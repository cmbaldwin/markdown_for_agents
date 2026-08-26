# frozen_string_literal: true

require_relative "test_helper"

class MiddlewareTest < MarkdownForAgents::TestCase
  def test_converts_html_when_accept_is_markdown
    status, headers, body = request(html_app)
    assert_equal 200, status
    assert_match(%r{\Atext/markdown}, headers["content-type"])
    text = body.join
    assert_match(/# Hello/, text)
    refute_match(/<html/i, text)
    assert_equal "markdown_for_agents", headers["x-markdown-converter"]
    assert_includes headers["vary"], "Accept"
  end

  def test_claude_code_accept_header_prefers_markdown
    status, headers, = request(html_app, accept: "text/markdown, text/html, */*")
    assert_equal 200, status
    assert_match(%r{\Atext/markdown}, headers["content-type"])
  end

  def test_q_values_prefer_html
    status, headers, body = request(html_app, accept: "text/html, text/markdown;q=0.8")
    assert_equal 200, status
    assert_match(%r{\Atext/html}, headers["content-type"])
    assert_match(/<html/i, body.join)
  end

  def test_star_star_does_not_convert
    status, headers, = request(html_app, accept: "*/*")
    assert_equal 200, status
    assert_match(%r{\Atext/html}, headers["content-type"])
  end

  def test_does_not_406_when_inner_app_checks_accept
    inner = lambda do |env|
      accept = env["HTTP_ACCEPT"].to_s
      if accept.include?("text/markdown") && !accept.include?("text/html")
        [406, { "content-type" => "text/html" }, ["nope"]]
      else
        [200, { "content-type" => "text/html" }, ["<html><body><h1>Ok</h1></body></html>"]]
      end
    end
    status, headers, = request(inner, accept: "text/markdown")
    assert_equal 200, status
    assert_match(%r{\Atext/markdown}, headers["content-type"])
  end

  def test_skips_up
    status, headers, = request(html_app, path: "/up")
    assert_equal 200, status
    assert_match(%r{\Atext/html}, headers["content-type"])
  end

  def test_skips_json_api
    app = html_app(type: "application/json", body: '{"ok":true}')
    status, headers, body = request(app, path: "/api/v1/posts", accept: "text/markdown")
    assert_equal 200, status
    assert_equal "application/json", headers["content-type"]
    assert_equal '{"ok":true}', body.join
  end

  def test_skips_non_2xx
    status, headers, = request(html_app(status: 404), accept: "text/markdown")
    assert_equal 404, status
    assert_match(%r{\Atext/html}, headers["content-type"])
  end

  def test_convert_flag_off_still_rewrites_accept
    MarkdownForAgents.convert = false
    inner = lambda do |env|
      if env["HTTP_ACCEPT"] == "text/html"
        [200, { "content-type" => "text/html" }, ["<html><body><h1>Hi</h1></body></html>"]]
      else
        [406, { "content-type" => "text/html" }, ["nope"]]
      end
    end
    status, headers, body = request(inner, accept: "text/markdown")
    assert_equal 200, status
    assert_match(%r{\Atext/html}, headers["content-type"])
    assert_match(/<html/i, body.join)
  end

  def test_preserves_existing_vary
    _status, headers, = request(html_app(extra: { "vary" => "Accept-Encoding" }))
    assert_includes headers["vary"], "Accept-Encoding"
    assert_includes headers["vary"], "Accept"
  end

  def test_skips_oversized_body
    MarkdownForAgents.max_bytes = 16
    status, headers, = request(html_app(body: "<html><body>#{'x' * 100}</body></html>"))
    assert_equal 200, status
    assert_match(%r{\Atext/html}, headers["content-type"])
  end
end
