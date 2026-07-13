# heedkit-sdk-ruby — Guide for Claude Code

Ruby SDK for HeedKit. Gem name `heedkit` on RubyGems, **v0.1.0**. **Dogfooded by the
backend** — `heedkit-rails/Gemfile` pulls this gem from GitHub to render HeedKit's own
`/roadmap`, `/changelog`, and feedback widget, so changes here can affect the live product.

- **Toolchain:** Ruby + `heedkit.gemspec`; version in `lib/heedkit/version.rb`.
- **Source (`lib/heedkit/`):** `client.rb` (HeedKit `/sdk/*` API + HMAC identity — the core),
  `roadmap.rb`, `changelog.rb`, `railtie.rb` (Rails integration), `../heedkit.rb` (entry).
  Tests in `test/` (Minitest).
- **Build / test:** `rake` (default task = test) · `rake test`.
- **Publish (manual — no CI):** `gem build heedkit.gemspec` then `gem push heedkit-<ver>.gem`.
  Bump `lib/heedkit/version.rb` first. Since the backend consumes this via `git:` (not a
  pinned version), pushing a commit changes what the app resolves — coordinate with
  `heedkit-rails`.

**Contract:** the backend `/sdk/*` JSON API (init → HMAC identity → replay token), mirrored
across all SDKs. See `../CLAUDE.md` for the monorepo map and §7 of `heedkit-rails/CLAUDE.md`
for the contract.
