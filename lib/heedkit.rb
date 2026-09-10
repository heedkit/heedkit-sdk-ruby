# frozen_string_literal: true

require "heedkit/version"
require "heedkit/roadmap"
require "heedkit/changelog"
require "heedkit/client"

# Ruby / Rails SDK for HeedKit — fetch a workspace's public roadmap and drive the
# end-user feedback API (identify / list / submit / vote / comment) from your server.
#
#   HeedKit.configure do |c|
#     c.workspace_key = "fk_..."
#     c.endpoint    = "https://heedkit.com"        # your HeedKit ORIGIN (no /sdk suffix)
#   end
#
#   HeedKit.roadmap            # => HeedKit::Roadmap
#   HeedKit.client.identify(external_id: "u-1")
module HeedKit
  class Error < StandardError
    attr_reader :status, :code

    def initialize(message, status: nil, code: nil)
      super(message)
      @status = status
      @code = code
    end
  end

  class Configuration
    # secret_key is the workspace's SERVER secret (fk_secret_…) — set it so
    # Client#identify can sign external ids (user_hash). Keep it out of anything
    # that reaches a browser or app binary.
    attr_accessor :workspace_key, :endpoint, :secret_key, :timeout

    def initialize
      @endpoint = "https://heedkit.com"
      @timeout = 5
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    # A client built from the global configuration.
    def client
      Client.new(workspace_key: configuration.workspace_key, endpoint: configuration.endpoint,
                 secret_key: configuration.secret_key, timeout: configuration.timeout)
    end

    def roadmap
      client.roadmap
    end

    def changelog
      client.changelog
    end
  end
end

require "heedkit/railtie" if defined?(::Rails::Railtie)
