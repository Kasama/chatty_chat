defmodule ChattyChat.Repo do
  use Ecto.Repo,
    otp_app: :chatty_chat,
    adapter: Ecto.Adapters.Postgres
end
