# frozen_string_literal: true

require "heedkit/version"
require "heedkit/roadmap"
require "heedkit/changelog"
require "heedkit/client"

# Ruby / Rails SDK for HeedKit — fetch a project's public roadmap and drive the
# end-user feedback API (identify / list / submit / vote / comment) from your server.
#
#   HeedKit.configure do |c|
#     c.project_key = "fk_..."
#     c.endpoint    = "https://acme.heedkit.com"   # your HeedKit base URL
#   end
#
#   HeedKit.roadmap            # => HeedKit::Roadmap
#   HeedKit.client.identify(external_id: "u-1")
module HeedKit
  class Error < StandardError; end

  class Configuration
    attr_accessor :project_key, :endpoint, :timeout

    def initialize
      @endpoint = "https://api.heedkit.com"
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
      Client.new(project_key: configuration.project_key, endpoint: configuration.endpoint, timeout: configuration.timeout)
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
