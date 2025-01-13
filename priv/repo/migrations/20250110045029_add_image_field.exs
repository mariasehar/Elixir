defmodule TodoApp.Repo.Migrations.AddImageField do
  use Ecto.Migration

  def change do
    alter table(:todos) do

      add :image, :string

    end
  end
end
