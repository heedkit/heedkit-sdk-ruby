# frozen_string_literal: true

require "test_helper"

class HeedKitTest < Minitest::Test
  def test_roadmap_from_payload
    payload = {
      "workspace_name" => "Acme",
      "theme" => { "primary" => "#123456" },
      "columns" => { "planned" => [ { "id" => 1, "title" => "Dark mode", "vote_count" => 3, "tag" => "ui" } ] }
    }
    roadmap = HeedKit::Roadmap.from_payload(payload)

    assert_equal "Acme", roadmap.workspace_name
    assert_equal "#123456", roadmap.primary_color
    assert_equal 1, roadmap.total

    columns = roadmap.each_column.to_a
    assert_equal %w[planned in_progress shipped], columns.map(&:first)
    assert_equal "Planned", columns.first[1]
    item = columns.first[2].first
    assert_equal "Dark mode", item.title
    assert_equal 3, item.vote_count
  end

  def test_changelog_from_payload
    payload = {
      "workspace_name" => "Acme",
      "theme" => { "primary" => "#123456" },
      "entries" => [
        { "id" => 2, "title" => "Dark mode", "body" => "**ship**", "category" => "new",
          "published_at" => "2026-06-01T00:00:00Z" }
      ]
    }
    changelog = HeedKit::Changelog.from_payload(payload)

    assert_equal "Acme", changelog.workspace_name
    assert_equal "#123456", changelog.primary_color
    assert_equal 1, changelog.size
    entry = changelog.first
    assert_equal "Dark mode", entry.title
    assert_equal "New", entry.category_label
    assert_instance_of Time, entry.published_at
  end

  def test_changelog_suggested_by_is_additive_and_nil_safe
    payload = {
      "workspace_name" => "Acme",
      "entries" => [
        { "id" => 1, "suggested_by" => "Ada Lovelace" },
        { "id" => 2 },
        { "id" => 3, "suggested_by" => nil },
        { "id" => 4, "suggested_by" => "" }
      ]
    }

    entries = HeedKit::Changelog.from_payload(payload).entries

    assert_equal "Ada Lovelace", entries[0].suggested_by
    assert_predicate entries[0], :suggested?
    entries.drop(1).each do |entry|
      assert_nil entry.suggested_by
      refute_predicate entry, :suggested?
    end
  end

  def test_changelog_over_http
    body = '{"workspace_name":"Demo","theme":{},"entries":[{"id":9,"title":"Done","body":"x","category":"fixed","published_at":"2026-05-01T00:00:00Z"}]}'
    with_stub_server(body: body) do |endpoint|
      changelog = HeedKit::Client.new(workspace_key: "fk_test", endpoint: endpoint).changelog
      assert_equal "Demo", changelog.workspace_name
      assert_equal "Fixed", changelog.first.category_label
    end
  end

  def test_client_requires_key_and_endpoint
    assert_raises(ArgumentError) { HeedKit::Client.new(workspace_key: "", endpoint: "http://x") }
    assert_raises(ArgumentError) { HeedKit::Client.new(workspace_key: "k", endpoint: "") }
  end

  def test_roadmap_over_http
    body = '{"workspace_name":"Demo","theme":{},"columns":{"shipped":[{"id":9,"title":"Done","vote_count":5}]}}'
    with_stub_server(body: body) do |endpoint|
      roadmap = HeedKit::Client.new(workspace_key: "fk_test", endpoint: endpoint).roadmap
      assert_equal "Demo", roadmap.workspace_name
      assert_equal "Done", roadmap.columns["shipped"].first.title
    end
  end

  def test_raises_on_error_status
    with_stub_server(status: "401 Unauthorized", body: '{"error":"invalid_workspace_key"}') do |endpoint|
      client = HeedKit::Client.new(workspace_key: "fk_bad", endpoint: endpoint)
      assert_raises(HeedKit::Error) { client.identify(external_id: "u-1") }
    end
  end

  def test_wraps_transport_errors
    # Nothing is listening on port 1 — the Errno is wrapped as HeedKit::Error.
    client = HeedKit::Client.new(workspace_key: "fk_x", endpoint: "http://127.0.0.1:1", timeout: 1)
    assert_raises(HeedKit::Error) { client.roadmap }
  end

  def test_global_configuration
    HeedKit.configure do |c|
      c.workspace_key = "fk_global"
      c.endpoint = "https://example.test"
    end
    assert_equal "fk_global", HeedKit.client.workspace_key
    assert_equal "https://example.test", HeedKit.client.endpoint
  end
end
