defmodule ElixirLlm.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirLlmWeb.Telemetry,
      ElixirLlm.Repo,
      {DNSCluster, query: Application.get_env(:elixir_llm, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElixirLlm.PubSub},
      {Redix, {Application.get_env(:elixir_llm, :redis_url, "redis://localhost:6379"), [name: :redix]}},
      ElixirLlmWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirLlm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirLlmWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
