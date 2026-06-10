# frozen_string_literal: true

module HeedKit
  # Exposes a `heedkit` accessor (the configured client) to controllers and views.
  module Helper
    def heedkit
      HeedKit.client
    end
  end

  class Railtie < ::Rails::Railtie
    initializer "heedkit.helper" do
      ActiveSupport.on_load(:action_controller) do
        include HeedKit::Helper
        helper HeedKit::Helper if respond_to?(:helper)
      end
    end
  end
end
