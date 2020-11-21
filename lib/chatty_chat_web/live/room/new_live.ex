defmodule ChattyChatWeb.Room.NewLive do
  use ChattyChatWeb, :live_view

  alias ChattyChat.Organizer.Room
  alias ChattyChat.Repo

  @impl true
  def render(assigns) do
    ~L"""
    <h1>Create New Room</h1>
    <div>
      <%= form_for @changeset, "#", [phx_change: "validate", phx_submit: "save"], fn f -> %>
        <%= text_input f, :title, placeholder: "Title" %>
        <%= error_tag f, :title %>
        <%= text_input f, :id, placeholder: "room-id" %>
        <%= error_tag f, :id %>
        <%= submit "Save" %>
      <% end %>
      <a href="<%= Routes.list_path(@socket, :list) %>"><button> View all rooms </button></a>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket |> put_changeset
    }
  end

  @impl true
  def handle_event("validate", %{"room" => room_params}, socket) do
    {:noreply,
      socket
      |> put_changeset(room_params)
    }
  end

  @impl true
  def handle_event("save", _, %{assigns: %{changeset: changeset}} = socket) do
    case Repo.insert(changeset) do
      {:ok, room} ->
        {:noreply,
          socket
          |> push_redirect(to: Routes.show_path(socket, :show, room.id))
          |> assign(:socket, socket)
        }
      {:error, changeset} ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)
          |> assign(:socket, socket)
          |> put_flash(:error, "Could not save the room.")
        }
    end
  end

  defp put_changeset(socket, params \\ %{}) do
    socket
      |> assign(:changeset, Room.changeset(%Room{}, params))
  end
end
