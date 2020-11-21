defmodule ChattyChat.Organizer.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  @fields [:title, :id]

  schema "rooms" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> format_id
    |> unique_constraint(:id)
  end

  defp format_id(%Ecto.Changeset{changes: %{id: _}} = changeset) do
    changeset
    |> update_change(:id, fn id ->
      id
      |> String.downcase
      |> String.replace(" ", "-")
    end)
  end

  defp format_id(changeset), do: changeset
end
