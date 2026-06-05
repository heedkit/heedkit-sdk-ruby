# frozen_string_literal: true

require "featurekit/version"
require "featurekit/roadmap"
require "featurekit/changelog"
require "featurekit/client"

# Ruby / Rails SDK for FeatureKit — fetch a project's public roadmap and drive the
# end-user feedback API (identify / list / submit / vote / comment) from your server.
#
#   FeatureKit.configure do |c|
#     c.project_key = "fk_..."
#     c.endpoint    = "https://acme.featurekit.app"   # your FeatureKit base URL
#   end
#
#   FeatureKit.roadmap            # => FeatureKit::Roadmap
#   FeatureKit.client.identify(external_id: "u-1")
module FeatureKit
  class Error < StandardError; end

  class Configuration
    attr_accessor :project_key, :endpoint, :timeout

    def initialize
      @endpoint = "https://api.featurekit.dev"
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

require "featurekit/railtie" if defined?(::Rails::Railtie)
