defmodule TodoAppWeb.BarLive.Index do
  use TodoAppWeb, :live_view

  alias TodoApp.Bars
  alias TodoApp.Bars.Bar


  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TodoApp.PubSub, "topic")
    end

    bars = Bars.list_bars()
    {:ok, assign(socket, bars: bars, search_query: "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Bar")
    |> assign(:bar, Bars.get_bar!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Bar")
    |> assign(:bar, %Bar{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Bars")
    |> assign(:bar, nil)
  end

  @impl true
  def handle_info({TodoAppWeb.BarLive.FormComponent, {:saved, _bar}}, socket) do
    {:noreply, assign(socket, :bars, Bars.list_bars())}
  end

  def handle_info({:bar, _bar}, socket) do
    {:noreply, assign(socket, bars: Bars.list_bars())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    bar = Bars.get_bar!(id)
    {:ok, _} = Bars.delete_bar(bar)

    {:noreply, assign(socket, :bars, Bars.list_bars())}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    bars = Bars.search_bars(query)
    {:noreply, assign(socket, :bars, bars)}
  end

end
