defmodule TodoApp.Context.Cruds do
  alias TodoApp.Crud
  alias TodoApp.Repo
  alias TodoApp.Crud

  def change_user(crud, params) do
    Crud.changeset(crud, params)
  end

  def create_user(changeset) do
    Repo.insert(changeset)
  end

  def list_all() do
    Repo.all(Crud)
  end

  def get_data(id) do
    Crud
    |> Repo.get(id)
  end

  def delete(id) do
    get_data(id)
    |> Repo.delete()
  end

  def update(crud, params) do
    Crud.changeset(crud, params)
    |> Repo.update()
  end
end
