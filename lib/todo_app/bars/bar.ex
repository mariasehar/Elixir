defmodule TodoApp.Bars.Bar do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bars" do
    field :name, :string
    field :status, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bar, attrs) do
    bar
    |> cast(attrs, [:name, :status])
    |> validate_required([:name, :status])
  end
end
