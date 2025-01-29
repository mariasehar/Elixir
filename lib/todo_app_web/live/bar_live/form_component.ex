defmodule TodoAppWeb.BarLive.FormComponent do
  use TodoAppWeb, :live_component

  alias TodoApp.Bars

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage bar records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="bar-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:status]} type="text" label="Status" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Bar</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{bar: bar} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Bars.change_bar(bar))
     end)}
  end

  @impl true
  def handle_event("validate", %{"bar" => bar_params}, socket) do
    changeset = Bars.change_bar(socket.assigns.bar, bar_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"bar" => bar_params}, socket) do
    save_bar(socket, socket.assigns.action, bar_params)
  end

  defp save_bar(socket, :edit, bar_params) do
    case Bars.update_bar(socket.assigns.bar, bar_params) do
      {:ok, bar} ->
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "topic",{:bar, bar} )

        notify_parent({:saved, bar})

        {:noreply,
         socket
         |> put_flash(:info, "Bar updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_bar(socket, :new, bar_params) do
    case Bars.create_bar(bar_params) do
      {:ok, bar} ->
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "topic",{:bar, bar} )

        notify_parent({:saved, bar})

        {:noreply,
         socket
         |> put_flash(:info, "Bar created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
