defmodule TodoAppWeb.Live.Edit do
  use TodoAppWeb, :live_component
  alias TodoApp.Context.Cruds


  def update(%{crud: crud}=assigns,socket) do
  crud1=Cruds.change_user(crud,%{})
  {:ok, socket |>assign(assigns) |>assign(:crud1, crud1)}

end
  def handle_event("validate", params, socket) do
    IO.inspect(params, label: "Validated params")
    {:noreply, socket}
  end

  def handle_event("update", %{"crud" => params}, socket) do
    {:ok, crud}=Cruds.update(socket.assigns.crud1, params)
    Phoenix.PubSub.broadcast(TodoApp.PubSub, "topic", {:crud, crud})

    socket =
      socket
      |> put_flash(:info, "UPDATED SUCCESSFULLY")
      |> push_navigate(to: ~p"/list")

    {:noreply, socket}
  end
end
