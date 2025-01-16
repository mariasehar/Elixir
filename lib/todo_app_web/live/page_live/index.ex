defmodule TodoAppWeb.PageLive.Index do
  use TodoAppWeb, :live_view

  alias TodoApp.Pages
  alias TodoApp.Pages.Page
  # import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    page_number = 1
    total_entries = Enum.count(Pages.list_pages())
    total_pages = (total_entries / 5) |> ceil()

    {:ok,
     socket
     |> assign(:pages, Pages.list_pages(page_number))
     |> assign(:total_pages, total_pages)
     |> assign(:page_number, page_number)}
  end

  @impl true
  def handle_params(%{"page" => page_number} = params, _url, socket) do
    page_number = page_number |> String.to_integer()
    pages = Pages.list_pages(page_number)

    socket =
      socket
      |> assign(:page_number, page_number)
      |> assign(:pages, pages)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_params(%{} = params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Page")
    |> assign(:page, Pages.get_page!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Page")
    |> assign(:page, %Page{})
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Listing Pages")
    |> assign(:page, nil)
  end

  @impl true
  def handle_info({TodoAppWeb.PageLive.FormComponent, {:saved, page}}, socket) do
    {:noreply, socket |> assign(:pages, Pages.create_page(page))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    page = Pages.get_page!(id)
    {:ok, _} = Pages.delete_page(page)

    {:noreply,
     socket
     |> assign(:pages, Pages.list_pages())}
  end
end
