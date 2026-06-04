# frozen_string_literal: true

module FeatureKit
  # Exposes a `featurekit` accessor (the configured client) to controllers and views.
  module Helper
    def featurekit
      FeatureKit.client
    end
  end

  class Railtie < ::Rails::Railtie
    initializer "featurekit.helper" do
      ActiveSupport.on_load(:action_controller) do
        include FeatureKit::Helper
        helper FeatureKit::Helper if respond_to?(:helper)
      end
    end
  end
end
