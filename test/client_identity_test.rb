# frozen_string_literal: true

require "test_helper"

# Wire-level identity contract: user_hash is computed from the secret (or passed
# through), the identity token is replayed as X-HeedKit-Identity, and legacy
# end_user_id fields are gone. Vector: HMAC_SHA256("fk_secret_test_0123456789abcdef",
# "user-42") = 4c630c03... (same self-check vector as every other HeedKit SDK).
class ClientIdentityTest < Minitest::Test
  SECRET = "fk_secret_test_0123456789abcdef"
  VECTOR = "4c630c032f4ff66a3e6379eca16cfc5fc40b231d6aeb1cd34c155efd3db54e7d"

  def client(endpoint, secret: SECRET)
    HeedKit::Client.new(workspace_key: "fk_test", endpoint: endpoint, secret_key: secret)
  end

  def test_user_hash_for_matches_the_cross_sdk_vector
    assert_equal VECTOR, client("http://unused").user_hash_for("user-42")
  end

  def test_user_hash_for_stringifies_and_requires_a_secret
    assert_equal VECTOR, client("http://unused").user_hash_for(:"user-42")
    err = assert_raises(HeedKit::Error) do
      HeedKit::Client.new(workspace_key: "fk_test", endpoint: "http://x").user_hash_for("u")
    end
    assert_match(/secret_key/, err.message)
  end

  def test_identify_signs_the_external_id_with_the_configured_secret
    captured = with_capturing_server(body: '{"end_user_id":7,"identity":"idtok-1"}') do |endpoint|
      client(endpoint).identify(external_id: "user-42", email: "a@b.c")
    end
    body = JSON.parse(captured[:body])
    assert_equal "fk_test", captured[:headers]["x-workspace-key"]
    assert_equal "user-42", body["external_id"]
    assert_equal VECTOR, body["user_hash"]
  end

  def test_identify_accepts_an_explicit_user_hash_without_a_secret
    captured = with_capturing_server do |endpoint|
      HeedKit::Client.new(workspace_key: "fk_test", endpoint: endpoint)
                     .identify(external_id: "u-1", user_hash: "deadbeef")
    end
    assert_equal "deadbeef", JSON.parse(captured[:body])["user_hash"]
  end

  def test_anonymous_identify_sends_no_external_id
    captured = with_capturing_server do |endpoint|
      client(endpoint).identify(email: "a@b.c")
    end
    body = JSON.parse(captured[:body])
    refute body.key?("external_id")
    refute body.key?("user_hash")
  end

  def test_authenticated_calls_replay_the_identity_token_without_legacy_params
    captured = with_capturing_server(body: '{"voted":true,"vote_count":1}') do |endpoint|
      client(endpoint).vote("42", identity: "idtok-1")
    end
    assert_equal "idtok-1", captured[:headers]["x-heedkit-identity"]
    refute_match(/end_user_id/, captured[:body])
    assert_equal "/sdk/features/42/vote", captured[:path]
  end

  def test_features_list_can_carry_an_identity_and_drops_end_user_id
    captured = with_capturing_server(body: '{"features":[]}') do |endpoint|
      client(endpoint).features(identity: "idtok-1", status: "planned")
    end
    assert_equal "idtok-1", captured[:headers]["x-heedkit-identity"]
    assert_includes captured[:path], "status=planned"
    refute_includes captured[:path], "end_user_id"
  end
end
