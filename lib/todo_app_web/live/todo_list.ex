defmodule TodoAppWeb.Live.TodoList do
  alias TodoApp.Todo
  alias TodoApp.Context.Todos
  use TodoAppWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, :todoo, Todos.list_todo())
    {:ok, socket}
  end

  @spec handle_params(any(), any(), map()) :: {:noreply, map()}
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def apply_action(socket, :todo_list, _params) do
    assign(socket, :todo, nil)
  end

  def apply_action(socket, :create, _params) do
    assign(socket, :todo, %Todo{})
  end

  def apply_action(socket, :update, %{"id" => id}) do
    assign(socket, :todo, Todos.get_todo!(id))
  end

  def apply_action(socket, :show, %{"id" => id}) do
    assign(socket, :todo, Todos.get_todo!(id))
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Todos.delete_todo(id)

    socket =
      socket
      |> put_flash(:info, "Successfully Deleted")

    {:noreply, assign(socket, :todoo, Todos.list_todo())}
  end
end
