defmodule TodoAppWeb.Live.Index do
  alias TodoApp.Context.Todos
  alias TodoApp.Todo
  use TodoAppWeb, :live_component

  def update(assigns, socket) do
    changeset = Todos.change_user(%Todo{}, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, changeset)}
  end

  def handle_event("save", %{"todo" => params}, socket) do
    IO.inspect(params, label: "saved params")
    changeset = Todos.change_user(%Todo{}, params)
    Todos.create_user(changeset)

    socket =
      socket
      |> put_flash(:info, "Successfully Saved")
      |> push_navigate(to: ~p"/todo_list")

    {:noreply, socket}
  end

  def handle_event("validate", params, socket) do
    IO.inspect(params, label: "validated params")
    {:noreply, socket}
  end
end
