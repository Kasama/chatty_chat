defmodule ChattyChatWeb.Presence do
  use Phoenix.Presence,
    otp_app: :chatty_chat,
    pubsub_server: ChattyChat.PubSub
end
