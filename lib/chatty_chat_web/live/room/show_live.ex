defmodule ChattyChatWeb.Room.ShowLive do
  use ChattyChatWeb, :live_view

  alias ChattyChat.Organizer
  alias ChattyChat.ConnectedUser

  alias ChattyChatWeb.Presence
  alias Phoenix.Socket.Broadcast

  @impl true
  def render(assigns) do
    ~L"""
    <h1><%= @room.title %> (<%= @room.id %>)</h1>
    <h3>Connected Users:</h3>
    <ul>
    <%= for uuid <- @connected_users do %>
      <li><%= uuid %></li>
    <% end %>
    </ul>
    <a href="<%= Routes.list_path(@socket, :list) %>"><button> View all rooms </button></a>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = create_connected_user()
    Phoenix.PubSub.subscribe(ChattyChat.PubSub, room_topic(id))
    {:ok, _} = Presence.track(self(), room_topic(id), user.uuid, %{})

    case Organizer.get_room(id) do
      nil ->
        {:ok,
          socket
          |> assign(:socket, socket)
          |> put_flash(:error, "Room does not exist.")
          |> push_redirect(to: Routes.new_path(socket, :new))
        }
      room ->
        {:ok,
          socket
          |> assign(:room, room)
          |> assign(:user, user)
          |> assign(:id, id)
          |> assign(:connected_users, [])
          |> assign(:socket, socket)
        }
    end
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply,
      socket
      |> assign(:connected_users, list_present(socket))
    }
  end

  defp room_topic(room_id) do
    "room:" <> room_id
  end

  defp list_present(socket) do
    Presence.list(room_topic socket.assigns.id)
      |> Enum.map(fn {k, _} -> k end)
  end

  defp create_connected_user do
    %ConnectedUser{uuid: UUID.uuid4()}
  end
end
