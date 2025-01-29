defmodule TodoApp.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todo" do
    field :name, :string
    field :status, :string
    field :description, :string
    timestamps()
  end

  def changeset(todo, params \\ %{}) do
    todo
    |> cast(params, [:name, :status, :description])
    |> validate_required([:name, :status, :description])
  end
end
