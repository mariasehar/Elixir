defmodule TodoApp.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :name, :string
      add :quantity, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:items, [:name])
  end
end
