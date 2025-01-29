defmodule TodoAppWeb.ChatSettingsLiveTest do
  use TodoAppWeb.ConnCase, async: true

  alias TodoApp.Chats
  import Phoenix.LiveViewTest
  import TodoApp.ChatsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_chat(chat_fixture())
        |> live(~p"/chats/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if chat is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/chats/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/chats/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_chat_password()
      chat = chat_fixture(%{password: password})
      %{conn: log_in_chat(conn, chat), chat: chat, password: password}
    end

    test "updates the chat email", %{conn: conn, password: password, chat: chat} do
      new_email = unique_chat_email()

      {:ok, lv, _html} = live(conn, ~p"/chats/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "chat" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Chats.get_chat_by_email(chat.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/chats/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "chat" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, chat: chat} do
      {:ok, lv, _html} = live(conn, ~p"/chats/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "chat" => %{"email" => chat.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_chat_password()
      chat = chat_fixture(%{password: password})
      %{conn: log_in_chat(conn, chat), chat: chat, password: password}
    end

    test "updates the chat password", %{conn: conn, chat: chat, password: password} do
      new_password = valid_chat_password()

      {:ok, lv, _html} = live(conn, ~p"/chats/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "chat" => %{
            "email" => chat.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/chats/settings"

      assert get_session(new_password_conn, :chat_token) != get_session(conn, :chat_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Chats.get_chat_by_email_and_password(chat.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/chats/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "chat" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/chats/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "chat" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      chat = chat_fixture()
      email = unique_chat_email()

      token =
        extract_chat_token(fn url ->
          Chats.deliver_chat_update_email_instructions(%{chat | email: email}, chat.email, url)
        end)

      %{conn: log_in_chat(conn, chat), token: token, email: email, chat: chat}
    end

    test "updates the chat email once", %{conn: conn, chat: chat, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/chats/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/chats/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Chats.get_chat_by_email(chat.email)
      assert Chats.get_chat_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/chats/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/chats/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, chat: chat} do
      {:error, redirect} = live(conn, ~p"/chats/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/chats/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Chats.get_chat_by_email(chat.email)
    end

    test "redirects if chat is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/chats/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/chats/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
