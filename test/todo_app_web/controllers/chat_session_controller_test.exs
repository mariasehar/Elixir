defmodule TodoAppWeb.ChatSessionControllerTest do
  use TodoAppWeb.ConnCase, async: true

  import TodoApp.ChatsFixtures

  setup do
    %{chat: chat_fixture()}
  end

  describe "POST /chats/log_in" do
    test "logs the chat in", %{conn: conn, chat: chat} do
      conn =
        post(conn, ~p"/chats/log_in", %{
          "chat" => %{"email" => chat.email, "password" => valid_chat_password()}
        })

      assert get_session(conn, :chat_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ chat.email
      assert response =~ ~p"/chats/settings"
      assert response =~ ~p"/chats/log_out"
    end

    test "logs the chat in with remember me", %{conn: conn, chat: chat} do
      conn =
        post(conn, ~p"/chats/log_in", %{
          "chat" => %{
            "email" => chat.email,
            "password" => valid_chat_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_todo_app_web_chat_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the chat in with return to", %{conn: conn, chat: chat} do
      conn =
        conn
        |> init_test_session(chat_return_to: "/foo/bar")
        |> post(~p"/chats/log_in", %{
          "chat" => %{
            "email" => chat.email,
            "password" => valid_chat_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, chat: chat} do
      conn =
        conn
        |> post(~p"/chats/log_in", %{
          "_action" => "registered",
          "chat" => %{
            "email" => chat.email,
            "password" => valid_chat_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, chat: chat} do
      conn =
        conn
        |> post(~p"/chats/log_in", %{
          "_action" => "password_updated",
          "chat" => %{
            "email" => chat.email,
            "password" => valid_chat_password()
          }
        })

      assert redirected_to(conn) == ~p"/chats/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/chats/log_in", %{
          "chat" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/chats/log_in"
    end
  end

  describe "DELETE /chats/log_out" do
    test "logs the chat out", %{conn: conn, chat: chat} do
      conn = conn |> log_in_chat(chat) |> delete(~p"/chats/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :chat_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the chat is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/chats/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :chat_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
