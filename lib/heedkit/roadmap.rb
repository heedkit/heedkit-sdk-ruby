# frozen_string_literal: true

module HeedKit
  # A single roadmap item.
  RoadmapItem = Struct.new(:id, :title, :description, :vote_count, :tag, keyword_init: true)

  # The public roadmap for a workspace: ordered status columns, each a list of items.
  class Roadmap
    # Column order matches the public roadmap, including items still in Backlog.
    STATUSES = %w[open planned in_progress shipped].freeze
    LABELS = { "open" => "Backlog", "planned" => "Planned", "in_progress" => "In progress", "shipped" => "Shipped" }.freeze

    attr_reader :workspace_name, :theme, :columns

    def self.from_payload(payload)
      cols = (payload["columns"] || {}).transform_values do |items|
        items.map do |i|
          RoadmapItem.new(id: i["id"], title: i["title"], description: i["description"],
                          vote_count: i["vote_count"], tag: i["tag"])
        end
      end
      new(workspace_name: payload["workspace_name"], theme: payload["theme"] || {}, columns: cols)
    end

    def initialize(workspace_name:, theme:, columns:)
      @workspace_name = workspace_name
      @theme = theme
      @columns = columns
    end

    def each_column
      return enum_for(:each_column) unless block_given?

      STATUSES.each { |status| yield status, LABELS[status], (columns[status] || []) }
    end

    def primary_color
      theme["primary"] || "#0d9488"
    end

    def total
      columns.values.sum(&:size)
    end
  end
end
