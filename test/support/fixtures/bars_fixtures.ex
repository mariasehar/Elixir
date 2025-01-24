defmodule TodoApp.BarsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TodoApp.Bars` context.
  """

  @doc """
  Generate a bar.
  """
  def bar_fixture(attrs \\ %{}) do
    {:ok, bar} =
      attrs
      |> Enum.into(%{
        name: "some name",
        status: "some status"
      })
      |> TodoApp.Bars.create_bar()

    bar
  end
end
