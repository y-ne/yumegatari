defmodule Yumegatari.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      YumegatariWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:yumegatari, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Yumegatari.PubSub},
      # Start a worker by calling: Yumegatari.Worker.start_link(arg)
      # {Yumegatari.Worker, arg},
      # Start to serve requests, typically the last entry
      YumegatariWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Yumegatari.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    YumegatariWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
