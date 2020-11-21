defmodule ChattyChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ChattyChat.Repo,
      # Start the Telemetry supervisor
      ChattyChatWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ChattyChat.PubSub},
      # Start Presence Module
      ChattyChatWeb.Presence,
      # Start the Endpoint (http/https)
      ChattyChatWeb.Endpoint
      # Start a worker by calling: ChattyChat.Worker.start_link(arg)
      # {ChattyChat.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChattyChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ChattyChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
