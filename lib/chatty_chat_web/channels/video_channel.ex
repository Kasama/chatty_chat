defmodule ChattyChatWeb.VideoChannel do
  use Phoenix.Channel

  def join(channel, _message, socket) do
    channel_id = channel |> String.split(":") |> List.last
    case ChattyChat.Organizer.get_room(channel_id) do
      nil -> {:error, "Room does not exist"}
      _ -> {:ok, socket}
    end
  end

  def handle_in("peer-message", %{"body" => body}, socket) do
    broadcast_from!(socket, "peer-message", %{body: body})
    {:noreply, socket}
  end
end
