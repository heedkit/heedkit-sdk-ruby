# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "openssl"

module HeedKit
  # Server-side client for the HeedKit API. Talks to the public roadmap endpoint
  # and the end-user SDK endpoints (X-Workspace-Key auth).
  #
  # Identity: this SDK runs where the workspace secret may live, so it can sign
  # identities itself — configure `secret_key` and #identify computes the required
  # user_hash automatically (or expose #user_hash_for to your frontend widget).
  # Authenticated calls (submit/vote/comment) take the `identity` token #identify
  # returned; the client is stateless so one instance can serve many end-users.
  class Client
    DEFAULT_TIMEOUT = 5

    attr_reader :workspace_key, :endpoint

    def initialize(workspace_key:, endpoint:, secret_key: nil, timeout: DEFAULT_TIMEOUT)
      raise ArgumentError, "workspace_key is required" if workspace_key.to_s.empty?
      raise ArgumentError, "endpoint is required" if endpoint.to_s.empty?

      @workspace_key = workspace_key
      @endpoint = endpoint.to_s.chomp("/")
      @secret_key = secret_key
      @timeout = timeout
    end

    # HMAC_SHA256(secret_key, external_id) as lowercase hex — the signature /sdk/init
    # requires alongside any external_id (unsigned ids are rejected with
    # 401 invalid_user_signature). Also handy for building the identity payload a
    # frontend widget fetches ({ externalId, userHash, name, email }).
    def user_hash_for(external_id)
      raise Error, "secret_key not configured — pass secret_key: to HeedKit::Client.new" if @secret_key.to_s.empty?

      OpenSSL::HMAC.hexdigest("SHA256", @secret_key, external_id.to_s)
    end

    # GET the public roadmap. Returns a HeedKit::Roadmap.
    def roadmap
      Roadmap.from_payload(get("/public/workspaces/#{workspace_key}/roadmap"))
    end

    # GET the public changelog. Returns a HeedKit::Changelog.
    def changelog
      Changelog.from_payload(get("/public/workspaces/#{workspace_key}/changelog"))
    end

    # POST /sdk/init — identify (find-or-create) an end-user. Returns the parsed body
    # ({ "end_user_id" => ..., "identity" => "<replay token>", "workspace" => {...} });
    # pass that "identity" to submit/vote/comment. With an external_id, user_hash is
    # computed from the configured secret_key when not given explicitly.
    def identify(external_id: nil, user_hash: nil, email: nil, name: nil, avatar_url: nil, platform: nil)
      user_hash ||= user_hash_for(external_id) if external_id && !@secret_key.to_s.empty?
      sdk_post("/sdk/init", external_id:, user_hash:, email:, name:, avatar_url:, platform:)
    end

    # GET /sdk/features — public features, plus the caller's own private submissions
    # when an identity token is given.
    def features(identity: nil, status: nil, kind: nil, sort: "top", cursor: nil)
      query = { status:, kind:, sort:, cursor: }.compact
      sdk_get("/sdk/features", query, identity:)
    end

    # POST /sdk/features — submit a feature as the end-user the token names.
    def submit(identity:, title:, description: nil, kind: "feature_request", tag: nil)
      sdk_post("/sdk/features", identity:, title:, description:, kind:, tag:)
    end

    # POST /sdk/features/:id/vote — toggle the end-user's vote.
    def vote(feature_id, identity:)
      sdk_post("/sdk/features/#{feature_id}/vote", identity:)
    end

    # POST /sdk/features/:id/comments — comment as the end-user the token names.
    def comment(feature_id, identity:, body:)
      sdk_post("/sdk/features/#{feature_id}/comments", identity:, body:)
    end

    private

    def sdk_get(path, query, identity: nil)
      get(path, query:, headers: key_header(identity))
    end

    def sdk_post(path, identity: nil, **body)
      post(path, body: body.compact, headers: key_header(identity))
    end

    # Workspace key + (when present) the signed identity replay token. The caller is
    # identified by this header, never by body params.
    def key_header(identity = nil)
      h = { "X-Workspace-Key" => workspace_key }
      h["X-HeedKit-Identity"] = identity if identity
      h
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
        error_body = begin
          JSON.parse(res.body)
        rescue JSON::ParserError
          nil
        end
        raise Error.new("HeedKit API #{res.code} for #{uri.path}: #{res.body}",
                        status: res.code.to_i, code: error_body.is_a?(Hash) ? error_body["error"] : nil)
      end

      res.body.to_s.empty? ? {} : JSON.parse(res.body)
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON from HeedKit API: #{e.message}"
    rescue SocketError, SystemCallError, IOError, Timeout::Error, OpenSSL::SSL::SSLError => e
      # Wrap transport failures (connection refused, DNS, timeouts) in our own error
      # type so callers only need to rescue HeedKit::Error.
      raise Error, "HeedKit request to #{uri} failed: #{e.message}"
    end
  end
end
