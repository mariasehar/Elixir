defmodule TodoApp.Repo.Migrations.CreateUserForm do
  use Ecto.Migration

  def change do
    create table(:crud) do
      add :name, :string
      add :status, :string
      timestamps()
    end
  end
end
