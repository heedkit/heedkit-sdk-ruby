# frozen_string_literal: true

require "time"

module HeedKit
  # A single published changelog entry (release note). `body` is markdown; `published_at`
  # is a Time (or nil).
  ChangelogEntry = Struct.new(
    :id, :title, :body, :category, :category_label, :published_at, keyword_init: true
  ) do
    def date = published_at
  end

  # A project's public changelog: published entries, newest first.
  class Changelog
    CATEGORY_LABELS = {
      "new" => "New", "improved" => "Improved", "fixed" => "Fixed", "announcement" => "Announcement"
    }.freeze

    attr_reader :project_name, :theme, :entries

    def self.from_payload(payload)
      entries = (payload["entries"] || []).map do |e|
        ChangelogEntry.new(
          id: e["id"], title: e["title"], body: e["body"], category: e["category"],
          category_label: e["category_label"] || CATEGORY_LABELS[e["category"]] || e["category"],
          published_at: parse_time(e["published_at"])
        )
      end
      new(project_name: payload["project_name"], theme: payload["theme"] || {}, entries: entries)
    end

    def self.parse_time(value)
      return nil if value.to_s.empty?
      Time.iso8601(value.to_s)
    rescue ArgumentError
      nil
    end

    def initialize(project_name:, theme:, entries:)
      @project_name = project_name
      @theme = theme
      @entries = entries
    end

    include Enumerable
    def each(&block) = entries.each(&block)

    def primary_color
      theme["primary"] || "#0d9488"
    end

    def size = entries.size
  end
end
