defmodule TodoApp.Repo.Migrations.CreateBars do
  use Ecto.Migration

  def change do
    create table(:bars) do
      add :name, :string
      add :status, :string

      timestamps(type: :utc_datetime)
    end
  end
end
