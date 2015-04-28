defmodule Phoenix.Endpoint.AdapterTest do
  use ExUnit.Case, async: true
  alias Phoenix.Endpoint.Adapter

  setup do
    Application.put_env(:phoenix, AdapterApp.Endpoint, custom: true)
    System.put_env("PHOENIX_PORT", "8080")
    :ok
  end

  test "loads router configuration" do
    config = Adapter.config(:phoenix, AdapterApp.Endpoint)
    assert config[:otp_app] == :phoenix
    assert config[:custom] == true
    assert config[:render_errors] == [view: AdapterApp.ErrorView, format: "html"]
  end

  defmodule HTTPSEndpoint do
    def path(path), do: path
    def config(:https), do: [port: 443]
    def config(:url), do: [host: "example.com"]
    def config(:otp_app), do: :phoenix
    def config(:cache_static_lookup), do: false
  end

  defmodule HTTPEndpoint do
    def path(path), do: path
    def config(:https), do: false
    def config(:http), do: [port: 80]
    def config(:url), do: [host: "example.com"]
    def config(:otp_app), do: :phoenix
    def config(:cache_static_lookup), do: true
  end

  defmodule HTTPEnvVarEndpoint do
    def config(:https), do: false
    def config(:http), do: [port: {:system,"PHOENIX_PORT"}]
    def config(:url), do: [host: "example.com"]
    def config(:otp_app), do: :phoenix
    def config(:cache_static_lookup), do: true
  end

  defmodule URLEndpoint do
    def config(:https), do: false
    def config(:http), do: false
    def config(:url), do: [host: "example.com", port: 678, scheme: "random"]
  end

  defmodule StaticURLEndpoint do
    def config(:https), do: false
    def config(:http), do: false
    def config(:multiple_static_hosts) do
      [[host: "example1.com", port: 678, scheme: "random"],
       [host: "example2.com"],
       [host: "example3.com", port: 8888],
       [host: "example4.com", port: 669]]
    end
  end

  test "generates static url based on multiple assets hosts" do
    available_static_hosts = [
      {:cache, "http://example1.com:678"},
      {:cache, "http://example2.com"},
      {:cache, "http://example3.com:8888"},
      {:cache, "http://example4.com:669"}
    ]
    :random.seed(:erlang.now)

    assert Adapter.static_url(StaticURLEndpoint) in available_static_hosts
    assert Adapter.static_url(StaticURLEndpoint) in available_static_hosts
    assert Adapter.static_url(StaticURLEndpoint) in available_static_hosts
    assert Adapter.static_url(StaticURLEndpoint) in available_static_hosts
  end

  test "generates url" do
    assert Adapter.url(URLEndpoint) == {:cache, "random://example.com:678"}
    assert Adapter.url(HTTPEndpoint) == {:cache, "http://example.com"}
    assert Adapter.url(HTTPSEndpoint) == {:cache, "https://example.com"}
    assert Adapter.url(HTTPEnvVarEndpoint) == {:cache, "http://example.com:8080"}
  end

  test "static_path/2 returns file's path with lookup cache" do
    assert {:cache, "/phoenix.png?" <> _} =
             Adapter.static_path(HTTPEndpoint, "/phoenix.png")
    assert {:stale, "/images/unknown.png"} =
             Adapter.static_path(HTTPEndpoint, "/images/unknown.png")
  end

  test "static_path/2 returns file's path without lookup cache" do
    assert {:stale, "/phoenix.png?" <> _} =
             Adapter.static_path(HTTPSEndpoint, "/phoenix.png")
    assert {:stale, "/images/unknown.png"} =
             Adapter.static_path(HTTPSEndpoint, "/images/unknown.png")
  end
end
