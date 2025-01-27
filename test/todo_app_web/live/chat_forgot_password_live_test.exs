defmodule TodoAppWeb.ChatForgotPasswordLiveTest do
  use TodoAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TodoApp.ChatsFixtures

  alias TodoApp.Chats
  alias TodoApp.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/chats/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/chats/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/chats/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_chat(chat_fixture())
        |> live(~p"/chats/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{chat: chat_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, chat: chat} do
      {:ok, lv, _html} = live(conn, ~p"/chats/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", chat: %{"email" => chat.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Chats.ChatToken, chat_id: chat.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/chats/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", chat: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Chats.ChatToken) == []
    end
  end
end
