defmodule TodoApp.Repo.Migrations.CreateTodo do
  use Ecto.Migration

  def change do
    create table(:todo) do
      add :name, :string
      add :status, :string
      add :description, :string

      timestamps()
    end
  end
end
