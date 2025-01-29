defmodule TodoAppWeb.ChatConfirmationInstructionsLiveTest do
  use TodoAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TodoApp.ChatsFixtures

  alias TodoApp.Chats
  alias TodoApp.Repo

  setup do
    %{chat: chat_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/chats/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, chat: chat} do
      {:ok, lv, _html} = live(conn, ~p"/chats/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", chat: %{email: chat.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Chats.ChatToken, chat_id: chat.id).context == "confirm"
    end

    test "does not send confirmation token if chat is confirmed", %{conn: conn, chat: chat} do
      Repo.update!(Chats.Chat.confirm_changeset(chat))

      {:ok, lv, _html} = live(conn, ~p"/chats/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", chat: %{email: chat.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Chats.ChatToken, chat_id: chat.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/chats/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", chat: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Chats.ChatToken) == []
    end
  end
end
