defmodule TodoAppWeb.Live.LiveChat do
  use TodoAppWeb, :live_view


  def mount(_params, _session, socket) do
    if connected?(socket) do
      TodoAppWeb.Endpoint.subscribe(topic())
    end
    IO.inspect(socket.assigns.current_user, label: "my current user")
    {:ok, assign(socket, username: socket.assigns.current_user.email, messages: [])}
  end

  # defp username do
  #    "User #{:rand.uniform(100)}"
  # end
  def handle_info(%{event: "message", payload: message}, socket) do
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
  end

  def handle_event("send", %{"text" => text}, socket) do
    TodoAppWeb.Endpoint.broadcast(topic(), "message", %{text: text, name: socket.assigns.username})
    {:noreply, socket}
  end

  defp topic do
    "chat"
  end

end
