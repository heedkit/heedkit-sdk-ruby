# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module FeatureKit
  # Server-side client for the FeatureKit API. Talks to the public roadmap endpoint
  # and the end-user SDK endpoints (X-Project-Key auth).
  class Client
    DEFAULT_TIMEOUT = 5

    attr_reader :project_key, :endpoint

    def initialize(project_key:, endpoint:, timeout: DEFAULT_TIMEOUT)
      raise ArgumentError, "project_key is required" if project_key.to_s.empty?
      raise ArgumentError, "endpoint is required" if endpoint.to_s.empty?

      @project_key = project_key
      @endpoint = endpoint.to_s.chomp("/")
      @timeout = timeout
    end

    # GET the public roadmap. Returns a FeatureKit::Roadmap.
    def roadmap
      Roadmap.from_payload(get("/public/projects/#{project_key}/roadmap"))
    end

    # POST /sdk/init — identify (find-or-create) an end-user. Returns the parsed body
    # ({ "end_user_id" => ..., "project" => {...} }).
    def identify(external_id: nil, email: nil, name: nil, avatar_url: nil, platform: nil)
      sdk_post("/sdk/init", external_id:, email:, name:, avatar_url:, platform:)
    end

    # GET /sdk/features — public features plus the caller's own private submissions.
    def features(end_user_id: nil, status: nil, kind: nil, sort: "top", cursor: nil)
      query = { end_user_id:, status:, kind:, sort:, cursor: }.compact
      sdk_get("/sdk/features", query)
    end

    # POST /sdk/features — submit a feature on behalf of an end-user.
    def submit(end_user_id:, title:, description: nil, kind: "feature_request", tag: nil)
      sdk_post("/sdk/features", end_user_id:, title:, description:, kind:, tag:)
    end

    # POST /sdk/features/:id/vote — toggle a vote.
    def vote(feature_id, end_user_id:)
      sdk_post("/sdk/features/#{feature_id}/vote", end_user_id:)
    end

    # POST /sdk/features/:id/comments — comment as an end-user.
    def comment(feature_id, end_user_id:, body:)
      sdk_post("/sdk/features/#{feature_id}/comments", end_user_id:, body:)
    end

    private

    def sdk_get(path, query)
      get(path, query:, headers: key_header)
    end

    def sdk_post(path, **body)
      post(path, body: body.compact, headers: key_header)
    end

    def key_header
      { "X-Project-Key" => project_key }
    end

    def get(path, query: {}, headers: {})
      uri = build_uri(path, query)
      request(Net::HTTP::Get.new(uri), uri, headers)
    end

    def post(path, body:, headers: {})
      uri = build_uri(path)
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req.body = JSON.generate(body)
      request(req, uri, headers)
    end

    def build_uri(path, query = {})
      uri = URI.parse("#{endpoint}#{path}")
      uri.query = URI.encode_www_form(query) unless query.empty?
      uri
    end

    def request(req, uri, headers)
      headers.each { |k, v| req[k] = v }
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout

      res = http.request(req)
      unless res.code.to_i.between?(200, 299)
        raise Error, "FeatureKit API #{res.code} for #{uri.path}: #{res.body}"
      end

      res.body.to_s.empty? ? {} : JSON.parse(res.body)
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON from FeatureKit API: #{e.message}"
    end
  end
end
