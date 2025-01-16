defmodule TodoApp.PagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TodoApp.Pages` context.
  """

  @doc """
  Generate a page.
  """
  def page_fixture(attrs \\ %{}) do
    {:ok, page} =
      attrs
      |> Enum.into(%{
        name: "some name",
        status: "some status"
      })
      |> TodoApp.Pages.create_page()

    page
  end
end
