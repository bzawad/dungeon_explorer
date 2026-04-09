defmodule Dungeon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DungeonWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:dungeon, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Dungeon.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Dungeon.Finch},
      # Start a worker by calling: Dungeon.Worker.start_link(arg)
      # {Dungeon.Worker, arg},
      # Start to serve requests, typically the last entry
      DungeonWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dungeon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, _removed) do
    DungeonWeb.Endpoint.config_change(changed, [])
    :ok
  end
end
