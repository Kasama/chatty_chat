defmodule ChattyChatWeb.Room.ListLive do
  use ChattyChatWeb, :live_view

  alias ChattyChat.Organizer

  @impl true
  def render(assigns) do
    ~L"""
    <a href="<%= Routes.new_path(@socket, :new) %>"><button> Create new </button></a>
    <ul>
    <%= for room <- @rooms do %>
      <li><a href="<%= Routes.show_path(@socket, :show, room.id) %>"><%= room.title %> (<%= room.id %>)</a></li>
    <% end %>
    </ul>
    """
  end

  @impl true
  def mount(_, _session, socket) do
    case Organizer.list_rooms do
      nil ->
        {:ok,
          socket
          |> assign(:rooms, [])
          |> assign(:socket, socket)
        }
      rooms ->
        {:ok,
          socket
          |> assign(:rooms, rooms)
          |> assign(:socket, socket)
        }
    end
  end
end
