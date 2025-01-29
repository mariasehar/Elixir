defmodule TodoApp.Crud do
  use Ecto.Schema
  import Ecto.Changeset

  schema "crud" do
    field :name, :string
    field :status, :string
    timestamps()
  end

  def changeset(crud, params \\ %{}) do
    crud
    |> cast(params, [:name, :status])
    |> validate_required([:name, :status])
  end
end
