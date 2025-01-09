defmodule TodoAppWeb.Live.Listing do
  use TodoAppWeb, :live_view
  alias TodoApp.Context.Cruds
  alias TodoApp.Crud

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TodoApp.PubSub, "topic")
    end
    {:ok,
     socket
     |> assign(:cruds, Cruds.list_all())}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Cruds.delete(id)

    socket =
      socket
      |> put_flash(:info, "User Deleted Successfully")
      |> push_navigate(to: ~p"/list")

    {:noreply,
     socket
     |> assign(:cruds, Cruds.list_all())}
  end


  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket,socket.assigns.live_action,params)}
  end

  def apply_action(socket,:list, _params) do
    assign(socket, :crud, nil)
  end
  def apply_action(socket,:create, _params) do
    assign(socket, :crud, %Crud{})
  end
  def apply_action(socket,:edit, %{"id"=>id}) do
    assign(socket, :crud, Cruds.get_data(id))
  end
  def apply_action(socket,:show, %{"id"=>id}) do
    assign(socket, :crud, Cruds.get_data(id))
  end

  def handle_info({:crud, crud}, socket) do
    {:noreply, assign(socket, cruds: socket.assigns.cruds ++ [crud])}
  end

end
