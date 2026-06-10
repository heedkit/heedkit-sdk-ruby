# frozen_string_literal: true

# HeedKit Ruby SDK — runnable demo against the Rails /sdk backend.
#
# Walks the full end-user feedback flow using ONLY methods that exist on
# HeedKit::Client (see ../lib/heedkit/client.rb):
#
#   identify  -> POST /sdk/init
#   features  -> GET  /sdk/features
#   submit    -> POST /sdk/features
#   vote      -> POST /sdk/features/:id/vote   (toggles)
#   comment   -> POST /sdk/features/:id/comments
#
# It also fetches the public roadmap + changelog (typed objects). This is a
# server-side client, so plain console output is the deliverable.
#
# Run:  bundle install && bundle exec ruby demo.rb
# (see README.md for prerequisites)

require "heedkit"

# ---------------------------------------------------------------------------
# CONFIG — override via env vars; defaults target the local Rails dev server.
# ---------------------------------------------------------------------------
# This is a non-browser (native) client, so use 127.0.0.1 per the dev-host
# notes. Browser SDKs would use http://heedkit.localhost:3000 instead.
ENDPOINT    = ENV.fetch("HEEDKIT_ENDPOINT", "http://127.0.0.1:3000")
# Get a real key from the Rails console Install page or db/seeds (the seeded
# "heedkit"/"demo" workspace). Never commit a real key.
PROJECT_KEY = ENV.fetch("HEEDKIT_PROJECT_KEY", "pk_REPLACE_ME")

def section(title)
  puts
  puts "== #{title} ".ljust(72, "=")
end

# Build a client straight from the constructor. (You could equally use
# HeedKit.configure { |c| ... } + HeedKit.client — same Client object.)
client = HeedKit::Client.new(project_key: PROJECT_KEY, endpoint: ENDPOINT)

puts "HeedKit demo -> #{ENDPOINT}"
if PROJECT_KEY == "pk_REPLACE_ME"
  puts "WARNING: using placeholder project key. Set HEEDKIT_PROJECT_KEY to a real key."
end

begin
  # -------------------------------------------------------------------------
  # 1) Public roadmap + changelog (typed objects, no end-user needed).
  # -------------------------------------------------------------------------
  section "Public roadmap"
  roadmap = client.roadmap
  puts "Project: #{roadmap.project_name}  (#{roadmap.total} items, theme #{roadmap.primary_color})"
  roadmap.each_column do |_status, label, items|
    puts "  #{label}: #{items.empty? ? '(none)' : items.map { |i| "#{i.title} (#{i.vote_count})" }.join(', ')}"
  end

  section "Public changelog"
  changelog = client.changelog
  puts "#{changelog.size} published entries"
  changelog.first(3).each do |entry|
    date = entry.published_at&.strftime("%Y-%m-%d") || "unpublished"
    puts "  [#{entry.category_label}] #{entry.title} — #{date}"
  end

  # -------------------------------------------------------------------------
  # 2) Identify (find-or-create) the end-user -> POST /sdk/init.
  # -------------------------------------------------------------------------
  section "Identify end-user"
  user = client.identify(
    external_id: "demo-user-1",
    email: "ada@example.com",
    name: "Ada Lovelace",
    platform: "web"
  )
  end_user_id = user["end_user_id"]
  project = user["project"] || {}
  puts "end_user_id = #{end_user_id}"
  puts "project: #{project['name']}  enabled_kinds=#{project['enabled_kinds'].inspect}"

  # -------------------------------------------------------------------------
  # 3) Fetch & display features (the feedback list / roadmap source).
  # -------------------------------------------------------------------------
  section "List features (sort=top)"
  listed = client.features(end_user_id: end_user_id, sort: "top")
  features = listed["features"] || []
  if features.empty?
    puts "  (no features yet)"
  else
    features.first(10).each do |f|
      mark = f["voted"] ? "*" : " "
      puts "  #{mark} [#{f['vote_count']}] #{f['title']}  <#{f['status']}/#{f['kind']}>  id=#{f['id']}"
    end
  end

  # -------------------------------------------------------------------------
  # 4) Submit a new feature -> POST /sdk/features.
  # -------------------------------------------------------------------------
  section "Submit a feature"
  created = client.submit(
    end_user_id: end_user_id,
    title: "Dark mode for the dashboard",
    description: "Please add a system-aware dark theme.",
    kind: "feature_request"
  )
  feature_id = created["id"]
  puts "created feature id=#{feature_id}  title=#{created['title'].inspect}"

  # -------------------------------------------------------------------------
  # 5) Upvote the feature (toggle) -> POST /sdk/features/:id/vote.
  # -------------------------------------------------------------------------
  section "Vote (toggle)"
  voted = client.vote(feature_id, end_user_id: end_user_id)
  puts "voted=#{voted['voted']}  vote_count=#{voted['vote_count']}"

  # -------------------------------------------------------------------------
  # 6) Add a comment -> POST /sdk/features/:id/comments.
  # -------------------------------------------------------------------------
  section "Comment"
  comment = client.comment(feature_id, end_user_id: end_user_id, body: "Yes please — would use this daily.")
  puts "comment id=#{comment['id']} by #{comment.dig('author', 'name') || comment['author']}: #{comment['body']}"

  section "Done"
  puts "Full flow completed against #{ENDPOINT}."
rescue HeedKit::Error => e
  # All SDK methods wrap transport + non-2xx responses in HeedKit::Error.
  warn
  warn "HeedKit error: #{e.message}"
  warn "Is the Rails server running (cd heedkit-rails && bin/dev) and is HEEDKIT_PROJECT_KEY a valid key?"
  exit 1
end
