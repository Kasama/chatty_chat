defmodule ChattyChat.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms, primary_key: false) do
      add :title, :string
      add :id, :string, primary_key: true

      timestamps()
    end

    create unique_index(:rooms, :id)
  end
end
