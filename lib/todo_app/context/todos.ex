defmodule TodoApp.Context.Todos do
  alias TodoApp.Repo
  alias TodoApp.Todo

  def change_user(todo, params) do
    Todo.changeset(todo, params)
  end

  def create_user(changeset) do
    Repo.insert(changeset)
  end

  def list_todo() do
    Todo
    |> Repo.all()
  end

  def get_todo!(id) do
    Todo
    |> Repo.get!(id)
  end

  def delete_todo(id) do
    get_todo!(id)
    |> Repo.delete()
  end

  def update_user(todo, params) do
    Todo.changeset(todo, params)
    |> Repo.update()
  end
end
