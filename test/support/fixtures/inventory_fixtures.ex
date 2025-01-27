defmodule TodoApp.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TodoApp.Inventory` context.
  """

  @doc """
  Generate a unique item name.
  """
  def unique_item_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a item.
  """
  def item_fixture(attrs \\ %{}) do
    {:ok, item} =
      attrs
      |> Enum.into(%{
        name: unique_item_name(),
        quantity: 42
      })
      |> TodoApp.Inventory.create_item()

    item
  end
end
