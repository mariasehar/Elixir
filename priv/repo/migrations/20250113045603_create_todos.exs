defmodule TodoApp.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos) do
      add :name, :string
      add :status, :string

      timestamps(type: :utc_datetime)
    end
  end
end
