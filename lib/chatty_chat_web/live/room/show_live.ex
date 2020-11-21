defmodule ChattyChatWeb.Room.ShowLive do
  use ChattyChatWeb, :live_view

  alias ChattyChat.Organizer
  alias ChattyChat.ConnectedUser

  alias ChattyChatWeb.Presence
  alias Phoenix.Socket.Broadcast

  @anon "Anonymous"

  @impl true
  def render(assigns) do
    ~L"""
    <h3>Your Name:</h3>
    <%= form_for :user, "#", [phx_submit: "update_name"], fn f -> %>
      <%= text_input f, :self_name, placeholder: @user.name %>
    <% end %>
    <h1><%= @room.title %> (<%= @room.id %>)</h1>
    <h3>Connected Users:</h3>
    <ul>
    <%= for user <- @connected_users do %>
      <li><%= user.name %> (<%= user.uuid %>)</li>
    <% end %>
    </ul>
    <a href="<%= Routes.list_path(@socket, :list) %>"><button> View all rooms </button></a>
    <section class="row">
      <article class="column">
        <label for="local-stream">Local Stream</label>
        <video id="local-stream" autoplay muted></video>
        <label for="remote-stream">Remote Stream</label>
        <video id="remote-stream" autoplay></video>

        <button id="connect">Connect</button>
        <button id="call">Call</button>
        <button id="disconnect">Disconnect</button>
      </article>
    </section>

    """
  end

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    user = create_connected_user(params |> Map.get("name", @anon))
    Phoenix.PubSub.subscribe(ChattyChat.PubSub, room_topic(id))
    {:ok, _} = Presence.track(self(), room_topic(id), user.uuid, user)

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

  @impl true
  def handle_event("update_name", %{"user" => user_params}, %{assigns: %{user: user, id: id}} = socket) do
    user_name_input = Map.get(user_params, "self_name", "")
    user_name = if (user_name_input |> String.length) == 0 do @anon else user_name_input end
    new_user = user |> Map.replace(:name, user_name)
    Presence.update(self(), room_topic(id), user.uuid, new_user)
    {:noreply,
      socket
      |> assign(:user, new_user)
      |> assign(:connected_users, list_present(socket))
      |> push_patch(to: Routes.show_path(socket, :show, id, name: user_name, room: id))
    }
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  defp room_topic(room_id) do
    "room:" <> room_id
  end

  defp list_present(socket) do
    Presence.list(room_topic socket.assigns.id)
      |> Enum.map(fn {_, v} -> List.first(v.metas) end)
  end

  defp create_connected_user(name) do
    %ConnectedUser{uuid: UUID.uuid4(), name: name}
  end
end
