# frozen_string_literal: true

require_relative "lib/heedkit/version"

Gem::Specification.new do |spec|
  spec.name        = "heedkit"
  spec.version     = HeedKit::VERSION
  spec.authors     = ["HeedKit"]
  spec.summary     = "Ruby / Rails SDK for HeedKit — public roadmap + feedback API"
  spec.description  = "Fetch a project's public roadmap and drive the end-user feedback API " \
                      "(identify / list / submit / vote / comment) from your Ruby or Rails server."
  spec.homepage     = "https://heedkit.com"
  spec.license      = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files        = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  # Runtime dependencies: none (stdlib net/http + json only).
end
