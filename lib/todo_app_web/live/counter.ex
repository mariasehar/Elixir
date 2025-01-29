defmodule TodoAppWeb.Live.Counter do
  use TodoAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:number, 0)}
  end

  def handle_event("add", %{"number1" => number}, socket) do
    {:noreply,
     socket
     |> assign(:number, number + 1)}
  end

  def handle_event("minus", %{"number2" => number}, socket) do
    {:noreply,
     socket
     |> assign(:number, number - 1)}
  end

  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, :number, 0)}
  end
end
