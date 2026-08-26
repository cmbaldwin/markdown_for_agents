# markdown_for_agents

Rack middleware for [Cloudflare Markdown for Agents](https://developers.cloudflare.com/fundamentals/reference/markdown-for-agents/).

Rails 8.1 registered `text/markdown`. Controllers without `format.md` return **406** when an agent sends `Accept: text/markdown`. This gem rewrites that Accept to HTML so the page still renders, then optionally converts the HTML to markdown.

In production, leave conversion **off** and enable Cloudflare `content_converter` on the zone. Cloudflare strips nav/chrome and adds YAML frontmatter. Origin conversion is for test/dev and Free-plan fallback.

## Install

```ruby
# Gemfile
gem "markdown_for_agents", github: "cmbaldwin/markdown_for_agents", tag: "v0.1.0"
```

Railtie inserts the middleware. No initializer required.

```yaml
# config/deploy.yml — production
env:
  clear:
    MARKDOWN_FOR_AGENTS_CONVERT: "0"   # "1" if the CF zone cannot enable Markdown for Agents
```

Defaults: convert **on** in development/test, **off** in production unless `MARKDOWN_FOR_AGENTS_CONVERT` is set.

## Non-Rails Rack

```ruby
# config.ru
require "markdown_for_agents"
MarkdownForAgents.convert = true
use MarkdownForAgents::Middleware
run MyApp
```

## What it skips

`/up`, `/health`, `/assets/*`, `/rails/*`, `/api/*`, `/mcp`, `/cable`, `*.json`, non-HTML, non-2xx, bodies over 2 MB.

## Verify

```bash
curl -sI -H "Accept: text/markdown" https://example.com/
# 200
# Content-Type: text/markdown
# never 406
```
