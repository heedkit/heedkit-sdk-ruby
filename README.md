# heedkit (Ruby / Rails SDK)

Server-side SDK for [HeedKit](https://heedkit.com). Fetch a workspace's **public
roadmap** and drive the **end-user feedback API** (identify / list / submit / vote /
comment) from any Ruby or Rails app.

```ruby
gem "heedkit"
```

## Configure

```ruby
HeedKit.configure do |c|
  c.workspace_key = ENV["HEEDKIT_WORKSPACE_KEY"]   # "fk_..."
  c.endpoint    = "https://heedkit.com"         # your HeedKit base URL
  c.secret_key  = ENV["HEEDKIT_SERVER_SECRET"] # "fk_secret_..." — lets identify() sign users
end
```

## Roadmap

```ruby
roadmap = HeedKit.roadmap            # => HeedKit::Roadmap
roadmap.workspace_name                    # "Acme Feedback"
roadmap.each_column do |status, label, items|
  puts "#{label}: #{items.map(&:title).join(', ')}"
end
```

In **Rails**, a `heedkit` helper (the configured client) is available in controllers
and views:

```erb
<% heedkit.roadmap.each_column do |status, label, items| %>
  <h3><%= label %></h3>
  <% items.each { |item| %><p><%= item.title %> · ▲ <%= item.vote_count %></p><% } %>
<% end %>
```

## Changelog

```ruby
HeedKit.changelog.each do |entry|
  puts "#{entry.category_label}: #{entry.title}"
  puts "💡 Suggested by #{entry.suggested_by}" if entry.suggested?
end
```

`ChangelogEntry#suggested_by` is the requester's display name when one was provided,
otherwise `nil`.

## Feedback API

```ruby
fk = HeedKit.client
# With secret_key configured, identify() signs the external_id automatically
# (the API rejects unsigned ids with 401 invalid_user_signature).
user = fk.identify(external_id: "user-123", email: "ada@example.com")
identity = user["identity"] # signed replay token — pass it to the calls below

fk.submit(identity:, title: "Dark mode", kind: "feature_request")
fk.features(identity:, sort: "top")      # identity optional here (anonymous list works)
fk.vote(feature_id, identity:)
fk.comment(feature_id, identity:, body: "Yes please")
```

The client is stateless — one instance can serve many end-users; each call carries the
`identity` token of the user it acts for (`X-HeedKit-Identity` header).

Serving a browser widget? Expose the signed payload from an authenticated route and pass
it to the JS SDK:

```ruby
# GET /heedkit/identity (authenticated)
render json: {
  externalId: current_user.id.to_s,
  userHash: HeedKit.client.user_hash_for(current_user.id),
  name: current_user.name, email: current_user.email
}
```

`identify` / `submit` / `features` / `vote` / `comment` authenticate with the workspace key
via the `X-Workspace-Key` header; `roadmap` reads the public endpoint. All methods raise
`HeedKit::Error` on a non-2xx response.

## License

MIT.
