defmodule TodoApp.Pages.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :name, :string
    field :status, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:name, :status])
    |> validate_required([:name, :status])
  end
end
