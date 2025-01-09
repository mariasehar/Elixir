defmodule TodoAppWeb.Live.Create do

  alias TodoApp.Crud
  alias TodoApp.Context.Cruds

  use TodoAppWeb, :live_component


def update(assigns, socket) do
  form = Crud.changeset(%Crud{}, %{})
  {:ok,socket|>assign(assigns) |> assign(:form, form)}
end
  def handle_event("validate", params, socket) do
    IO.inspect(params, label: "Validated params")
    {:noreply, socket}
  end

  def handle_event("save", %{"crud" => params}, socket) do
    changeset = Crud.changeset(%Crud{}, params)
    {:ok, crud}= Cruds.create_user(changeset)
    Phoenix.PubSub.broadcast(TodoApp.PubSub, "topic", {:crud, crud})

    socket =
      socket
      |> put_flash(:info, "User Created Successfully")
      |> push_navigate(to: ~p"/list")

    {:noreply, socket}
  end
def topic do
"recorded"
end

end
