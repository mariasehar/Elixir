defmodule TodoAppWeb.TodoLive.Index do
  use TodoAppWeb, :live_view
  import Ecto.Query, only: [from: 2]
  alias TodoApp.Todos
  alias TodoApp.Todos.Todo
  alias TodoApp.Repo

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:todos, Todos.list_todos())}
  end

  def handle_event("validate", %{"status" => _status, "id" => id} = params, socket) do
    IO.inspect(params, label: "validated params")
    todo = Todos.get_todo!(id)
    Todos.update_todo(todo, params)

    query =
      from t in Todo,
        where: t.status == false

    {:noreply, assign(socket, :todos ,Repo.all(query))}
  end


  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    Todos.delete_todo(todo)

    {:noreply, assign(socket, :todos, Todos.list_todos())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Todo")
    |> assign(:todo, Todos.get_todo!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Todo")
    |> assign(:todo, %Todo{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Todos")
    |> assign(:todo, Todos.list_todos())
  end

  @impl true
  def handle_info({TodoAppWeb.TodoLive.FormComponent, {:saved, _todo}}, socket) do
    {:noreply, assign(socket, :todos, Todos.list_todos())}
  end


end




