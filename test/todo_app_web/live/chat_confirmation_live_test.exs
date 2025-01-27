defmodule TodoAppWeb.ChatConfirmationLiveTest do
  use TodoAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TodoApp.ChatsFixtures

  alias TodoApp.Chats
  alias TodoApp.Repo

  setup do
    %{chat: chat_fixture()}
  end

  describe "Confirm chat" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/chats/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, chat: chat} do
      token =
        extract_chat_token(fn url ->
          Chats.deliver_chat_confirmation_instructions(chat, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/chats/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Chat confirmed successfully"

      assert Chats.get_chat!(chat.id).confirmed_at
      refute get_session(conn, :chat_token)
      assert Repo.all(Chats.ChatToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/chats/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Chat confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_chat(chat)

      {:ok, lv, _html} = live(conn, ~p"/chats/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, chat: chat} do
      {:ok, lv, _html} = live(conn, ~p"/chats/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Chat confirmation link is invalid or it has expired"

      refute Chats.get_chat!(chat.id).confirmed_at
    end
  end
end
