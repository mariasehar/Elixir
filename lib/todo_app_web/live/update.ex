defmodule TodoAppWeb.Live.Update do
  alias TodoApp.Context.Todos
  use TodoAppWeb, :live_component

  def update(%{todo: todo} = assigns, socket) do
    changeset = Todos.change_user(todo, %{})

    {:ok,
     socket
     |> assign(changeset: changeset)
     |> assign(assigns)}
  end

  def handle_event("update", %{"todo" => params}, socket) do
    Todos.update_user(socket.assigns.todo, params)

    socket =
      socket
      |> put_flash(:info, "Successfully Updated")
      |> push_navigate(to: ~p"/todo_list")

    {:noreply, socket}
  end

  def handle_event("validate", params, socket) do
    IO.inspect(params, label: "validated params")
    {:noreply, socket}
  end
end
