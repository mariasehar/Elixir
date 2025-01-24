defmodule TodoApp.BarsTest do
  use TodoApp.DataCase

  alias TodoApp.Bars

  describe "bars" do
    alias TodoApp.Bars.Bar

    import TodoApp.BarsFixtures

    @invalid_attrs %{name: nil, status: nil}

    test "list_bars/0 returns all bars" do
      bar = bar_fixture()
      assert Bars.list_bars() == [bar]
    end

    test "get_bar!/1 returns the bar with given id" do
      bar = bar_fixture()
      assert Bars.get_bar!(bar.id) == bar
    end

    test "create_bar/1 with valid data creates a bar" do
      valid_attrs = %{name: "some name", status: "some status"}

      assert {:ok, %Bar{} = bar} = Bars.create_bar(valid_attrs)
      assert bar.name == "some name"
      assert bar.status == "some status"
    end

    test "create_bar/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bars.create_bar(@invalid_attrs)
    end

    test "update_bar/2 with valid data updates the bar" do
      bar = bar_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status"}

      assert {:ok, %Bar{} = bar} = Bars.update_bar(bar, update_attrs)
      assert bar.name == "some updated name"
      assert bar.status == "some updated status"
    end

    test "update_bar/2 with invalid data returns error changeset" do
      bar = bar_fixture()
      assert {:error, %Ecto.Changeset{}} = Bars.update_bar(bar, @invalid_attrs)
      assert bar == Bars.get_bar!(bar.id)
    end

    test "delete_bar/1 deletes the bar" do
      bar = bar_fixture()
      assert {:ok, %Bar{}} = Bars.delete_bar(bar)
      assert_raise Ecto.NoResultsError, fn -> Bars.get_bar!(bar.id) end
    end

    test "change_bar/1 returns a bar changeset" do
      bar = bar_fixture()
      assert %Ecto.Changeset{} = Bars.change_bar(bar)
    end
  end
end
