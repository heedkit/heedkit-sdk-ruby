# frozen_string_literal: true

require "test_helper"

class FeatureKitTest < Minitest::Test
  def test_roadmap_from_payload
    payload = {
      "project_name" => "Acme",
      "theme" => { "primary" => "#123456" },
      "columns" => { "planned" => [ { "id" => 1, "title" => "Dark mode", "vote_count" => 3, "tag" => "ui" } ] }
    }
    roadmap = FeatureKit::Roadmap.from_payload(payload)

    assert_equal "Acme", roadmap.project_name
    assert_equal "#123456", roadmap.primary_color
    assert_equal 1, roadmap.total

    columns = roadmap.each_column.to_a
    assert_equal %w[planned in_progress shipped], columns.map(&:first)
    assert_equal "Planned", columns.first[1]
    item = columns.first[2].first
    assert_equal "Dark mode", item.title
    assert_equal 3, item.vote_count
  end

  def test_client_requires_key_and_endpoint
    assert_raises(ArgumentError) { FeatureKit::Client.new(project_key: "", endpoint: "http://x") }
    assert_raises(ArgumentError) { FeatureKit::Client.new(project_key: "k", endpoint: "") }
  end

  def test_roadmap_over_http
    body = '{"project_name":"Demo","theme":{},"columns":{"shipped":[{"id":9,"title":"Done","vote_count":5}]}}'
    with_stub_server(body: body) do |endpoint|
      roadmap = FeatureKit::Client.new(project_key: "fk_test", endpoint: endpoint).roadmap
      assert_equal "Demo", roadmap.project_name
      assert_equal "Done", roadmap.columns["shipped"].first.title
    end
  end

  def test_raises_on_error_status
    with_stub_server(status: "401 Unauthorized", body: '{"error":"invalid_project_key"}') do |endpoint|
      client = FeatureKit::Client.new(project_key: "fk_bad", endpoint: endpoint)
      assert_raises(FeatureKit::Error) { client.identify(external_id: "u-1") }
    end
  end

  def test_wraps_transport_errors
    # Nothing is listening on port 1 — the Errno is wrapped as FeatureKit::Error.
    client = FeatureKit::Client.new(project_key: "fk_x", endpoint: "http://127.0.0.1:1", timeout: 1)
    assert_raises(FeatureKit::Error) { client.roadmap }
  end

  def test_global_configuration
    FeatureKit.configure do |c|
      c.project_key = "fk_global"
      c.endpoint = "https://example.test"
    end
    assert_equal "fk_global", FeatureKit.client.project_key
    assert_equal "https://example.test", FeatureKit.client.endpoint
  end
end
