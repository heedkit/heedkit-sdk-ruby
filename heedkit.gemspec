# frozen_string_literal: true

require_relative "lib/heedkit/version"

Gem::Specification.new do |spec|
  spec.name        = "heedkit"
  spec.version     = HeedKit::VERSION
  spec.authors     = ["HeedKit"]
  spec.email       = ["support@heedkit.com"]
  spec.summary     = "Ruby / Rails SDK for HeedKit — public roadmap + feedback API"
  spec.description  = "Fetch a workspace's public roadmap and drive the end-user feedback API " \
                      "(identify / list / submit / vote / comment) from your Ruby or Rails server."
  spec.homepage     = "https://heedkit.com"
  spec.license      = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "homepage_uri"      => "https://heedkit.com",
    "source_code_uri"   => "https://github.com/heedkit/heedkit-sdk-ruby",
    "bug_tracker_uri"   => "https://github.com/heedkit/heedkit-sdk-ruby/issues",
    "allowed_push_host" => "https://rubygems.org",
    "rubygems_mfa_required" => "true"
  }

  spec.files        = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  # Runtime dependencies: none (stdlib net/http + json only).
end
