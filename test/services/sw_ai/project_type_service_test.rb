# frozen_string_literal: true

require "test_helper"

class SwAi::ProjectTypeServiceTest < ActiveSupport::TestCase
  def service_with(status:, body:)
    stubs = Faraday::Adapter::Test::Stubs.new do |s|
      s.post("/projects/type") { [ status, { "Content-Type" => "application/json" }, body.to_json ] }
    end
    svc = SwAi::ProjectTypeService.new(@project)
    svc.define_singleton_method(:connection) do |_api_key|
      Faraday.new(url: "https://ai.review.example.com") do |conn|
        conn.request  :json
        conn.response :json
        conn.adapter  :test, stubs
      end
    end
    svc
  end

  setup do
    @project = Project.new(title: "My App", description: "A web app")
    Rails.application.config.x.sw_ai.url     = "https://ai.review.example.com"
    Rails.application.config.x.sw_ai.api_key = "test-key"
  end

  test "returns type on success" do
    result = service_with(status: 200, body: { "type" => "Web App" }).call
    assert result.ok
    assert_equal "Web App", result.type
  end

  test "treats Unknown as nil type" do
    result = service_with(status: 200, body: { "type" => "Unknown" }).call
    assert result.ok
    assert_nil result.type
  end

  test "returns not-ok on non-200 response" do
    result = service_with(status: 422, body: {}).call
    assert_not result.ok
    assert_nil result.type
  end

  test "returns not-ok when api key is blank" do
    Rails.application.config.x.sw_ai.api_key = nil
    result = SwAi::ProjectTypeService.new(@project).call
    assert_not result.ok
    assert_nil result.type
  end

  test "re-raises on network error" do
    svc = SwAi::ProjectTypeService.new(@project)
    svc.define_singleton_method(:connection) { |_key| raise Errno::ECONNREFUSED }
    assert_raises(Errno::ECONNREFUSED) { svc.call }
  end
end
