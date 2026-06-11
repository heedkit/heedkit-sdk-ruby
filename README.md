# heedkit (Ruby / Rails SDK)

Server-side SDK for [HeedKit](https://heedkit.com). Fetch a project's **public
roadmap** and drive the **end-user feedback API** (identify / list / submit / vote /
comment) from any Ruby or Rails app.

```ruby
gem "heedkit"
```

## Configure

```ruby
HeedKit.configure do |c|
  c.project_key = ENV["HEEDKIT_PROJECT_KEY"]   # "fk_..."
  c.endpoint    = "https://acme.heedkit.com"   # your HeedKit base URL
end
```

## Roadmap

```ruby
roadmap = HeedKit.roadmap            # => HeedKit::Roadmap
roadmap.project_name                    # "Acme Feedback"
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

## Feedback API

```ruby
fk = HeedKit.client
user = fk.identify(external_id: "user-123", email: "ada@example.com")
fk.submit(end_user_id: user["end_user_id"], title: "Dark mode", kind: "feature_request")
fk.features(end_user_id: user["end_user_id"], sort: "top")
fk.vote(feature_id, end_user_id: user["end_user_id"])
fk.comment(feature_id, end_user_id: user["end_user_id"], body: "Yes please")
```

`identify` / `submit` / `features` / `vote` / `comment` authenticate with the project key
via the `X-Project-Key` header; `roadmap` reads the public endpoint. All methods raise
`HeedKit::Error` on a non-2xx response.

## License

MIT.
