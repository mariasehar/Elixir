defmodule TodoAppWeb.BarLiveTest do
  use TodoAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import TodoApp.BarsFixtures

  @create_attrs %{name: "some name", status: "some status"}
  @update_attrs %{name: "some updated name", status: "some updated status"}
  @invalid_attrs %{name: nil, status: nil}

  defp create_bar(_) do
    bar = bar_fixture()
    %{bar: bar}
  end

  describe "Index" do
    setup [:create_bar]

    test "lists all bars", %{conn: conn, bar: bar} do
      {:ok, _index_live, html} = live(conn, ~p"/bars")

      assert html =~ "Listing Bars"
      assert html =~ bar.name
    end

    test "saves new bar", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/bars")

      assert index_live |> element("a", "New Bar") |> render_click() =~
               "New Bar"

      assert_patch(index_live, ~p"/bars/new")

      assert index_live
             |> form("#bar-form", bar: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#bar-form", bar: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/bars")

      html = render(index_live)
      assert html =~ "Bar created successfully"
      assert html =~ "some name"
    end

    test "updates bar in listing", %{conn: conn, bar: bar} do
      {:ok, index_live, _html} = live(conn, ~p"/bars")

      assert index_live |> element("#bars-#{bar.id} a", "Edit") |> render_click() =~
               "Edit Bar"

      assert_patch(index_live, ~p"/bars/#{bar}/edit")

      assert index_live
             |> form("#bar-form", bar: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#bar-form", bar: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/bars")

      html = render(index_live)
      assert html =~ "Bar updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes bar in listing", %{conn: conn, bar: bar} do
      {:ok, index_live, _html} = live(conn, ~p"/bars")

      assert index_live |> element("#bars-#{bar.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#bars-#{bar.id}")
    end
  end

  describe "Show" do
    setup [:create_bar]

    test "displays bar", %{conn: conn, bar: bar} do
      {:ok, _show_live, html} = live(conn, ~p"/bars/#{bar}")

      assert html =~ "Show Bar"
      assert html =~ bar.name
    end

    test "updates bar within modal", %{conn: conn, bar: bar} do
      {:ok, show_live, _html} = live(conn, ~p"/bars/#{bar}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Bar"

      assert_patch(show_live, ~p"/bars/#{bar}/show/edit")

      assert show_live
             |> form("#bar-form", bar: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#bar-form", bar: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/bars/#{bar}")

      html = render(show_live)
      assert html =~ "Bar updated successfully"
      assert html =~ "some updated name"
    end
  end
end
