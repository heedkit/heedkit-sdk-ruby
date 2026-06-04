# featurekit (Ruby / Rails SDK)

Server-side SDK for [FeatureKit](https://featurekit.dev). Fetch a project's **public
roadmap** and drive the **end-user feedback API** (identify / list / submit / vote /
comment) from any Ruby or Rails app.

```ruby
gem "featurekit"
```

## Configure

```ruby
FeatureKit.configure do |c|
  c.project_key = ENV["FEATUREKIT_PROJECT_KEY"]   # "fk_..."
  c.endpoint    = "https://acme.featurekit.app"   # your FeatureKit base URL
end
```

## Roadmap

```ruby
roadmap = FeatureKit.roadmap            # => FeatureKit::Roadmap
roadmap.project_name                    # "Acme Feedback"
roadmap.each_column do |status, label, items|
  puts "#{label}: #{items.map(&:title).join(', ')}"
end
```

In **Rails**, a `featurekit` helper (the configured client) is available in controllers
and views:

```erb
<% featurekit.roadmap.each_column do |status, label, items| %>
  <h3><%= label %></h3>
  <% items.each { |item| %><p><%= item.title %> · ▲ <%= item.vote_count %></p><% } %>
<% end %>
```

## Feedback API

```ruby
fk = FeatureKit.client
user = fk.identify(external_id: "user-123", email: "ada@example.com")
fk.submit(end_user_id: user["end_user_id"], title: "Dark mode", kind: "feature_request")
fk.features(end_user_id: user["end_user_id"], sort: "top")
fk.vote(feature_id, end_user_id: user["end_user_id"])
fk.comment(feature_id, end_user_id: user["end_user_id"], body: "Yes please")
```

`identify` / `submit` / `features` / `vote` / `comment` authenticate with the project key
via the `X-Project-Key` header; `roadmap` reads the public endpoint. All methods raise
`FeatureKit::Error` on a non-2xx response.

## License

MIT.
