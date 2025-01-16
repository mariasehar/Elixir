defmodule TodoApp.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :name, :string
      add :status, :string

      timestamps(type: :utc_datetime)
    end
  end
end
