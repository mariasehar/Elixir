defmodule TodoAppWeb.BarLive.Show do
  use TodoAppWeb, :live_view

  alias TodoApp.Bars

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:bar, Bars.get_bar!(id))}
  end

  defp page_title(:edit), do: "Edit Bar"
end
