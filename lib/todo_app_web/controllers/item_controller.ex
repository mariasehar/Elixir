defmodule TodoAppWeb.ItemController do
  use TodoAppWeb, :controller

  alias TodoApp.Inventory
  alias TodoApp.Inventory.Item

  action_fallback TodoAppWeb.FallbackController

  def index(conn, _params) do
    items = Inventory.list_items()
    render(conn, :index, items: items)
  end

  def create(conn, %{"item" => item_params}) do
    with {:ok, %Item{} = item} <- Inventory.create_item(item_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/items/#{item}")
      |> render(:show, item: item)
    end
  end

  def show(conn, %{"id" => id}) do
    item = Inventory.get_item!(id)
    render(conn, :show, item: item)
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    item = Inventory.get_item!(id)

    with {:ok, %Item{} = item} <- Inventory.update_item(item, item_params) do
      render(conn, :show, item: item)
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Inventory.get_item!(id)

    with {:ok, %Item{}} <- Inventory.delete_item(item) do
      send_resp(conn, :no_content, "")
    end
  end
end
