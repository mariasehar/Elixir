defmodule TodoAppWeb.ChatAuthTest do
  use TodoAppWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias TodoApp.Chats
  alias TodoAppWeb.ChatAuth
  import TodoApp.ChatsFixtures

  @remember_me_cookie "_todo_app_web_chat_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, TodoAppWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{chat: chat_fixture(), conn: conn}
  end

  describe "log_in_chat/3" do
    test "stores the chat token in the session", %{conn: conn, chat: chat} do
      conn = ChatAuth.log_in_chat(conn, chat)
      assert token = get_session(conn, :chat_token)
      assert get_session(conn, :live_socket_id) == "chats_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Chats.get_chat_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, chat: chat} do
      conn = conn |> put_session(:to_be_removed, "value") |> ChatAuth.log_in_chat(chat)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, chat: chat} do
      conn = conn |> put_session(:chat_return_to, "/hello") |> ChatAuth.log_in_chat(chat)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, chat: chat} do
      conn = conn |> fetch_cookies() |> ChatAuth.log_in_chat(chat, %{"remember_me" => "true"})
      assert get_session(conn, :chat_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :chat_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_chat/1" do
    test "erases session and cookies", %{conn: conn, chat: chat} do
      chat_token = Chats.generate_chat_session_token(chat)

      conn =
        conn
        |> put_session(:chat_token, chat_token)
        |> put_req_cookie(@remember_me_cookie, chat_token)
        |> fetch_cookies()
        |> ChatAuth.log_out_chat()

      refute get_session(conn, :chat_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Chats.get_chat_by_session_token(chat_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "chats_sessions:abcdef-token"
      TodoAppWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> ChatAuth.log_out_chat()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if chat is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> ChatAuth.log_out_chat()
      refute get_session(conn, :chat_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_chat/2" do
    test "authenticates chat from session", %{conn: conn, chat: chat} do
      chat_token = Chats.generate_chat_session_token(chat)
      conn = conn |> put_session(:chat_token, chat_token) |> ChatAuth.fetch_current_chat([])
      assert conn.assigns.current_chat.id == chat.id
    end

    test "authenticates chat from cookies", %{conn: conn, chat: chat} do
      logged_in_conn =
        conn |> fetch_cookies() |> ChatAuth.log_in_chat(chat, %{"remember_me" => "true"})

      chat_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> ChatAuth.fetch_current_chat([])

      assert conn.assigns.current_chat.id == chat.id
      assert get_session(conn, :chat_token) == chat_token

      assert get_session(conn, :live_socket_id) ==
               "chats_sessions:#{Base.url_encode64(chat_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, chat: chat} do
      _ = Chats.generate_chat_session_token(chat)
      conn = ChatAuth.fetch_current_chat(conn, [])
      refute get_session(conn, :chat_token)
      refute conn.assigns.current_chat
    end
  end

  describe "on_mount :mount_current_chat" do
    test "assigns current_chat based on a valid chat_token", %{conn: conn, chat: chat} do
      chat_token = Chats.generate_chat_session_token(chat)
      session = conn |> put_session(:chat_token, chat_token) |> get_session()

      {:cont, updated_socket} =
        ChatAuth.on_mount(:mount_current_chat, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_chat.id == chat.id
    end

    test "assigns nil to current_chat assign if there isn't a valid chat_token", %{conn: conn} do
      chat_token = "invalid_token"
      session = conn |> put_session(:chat_token, chat_token) |> get_session()

      {:cont, updated_socket} =
        ChatAuth.on_mount(:mount_current_chat, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_chat == nil
    end

    test "assigns nil to current_chat assign if there isn't a chat_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        ChatAuth.on_mount(:mount_current_chat, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_chat == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "authenticates current_chat based on a valid chat_token", %{conn: conn, chat: chat} do
      chat_token = Chats.generate_chat_session_token(chat)
      session = conn |> put_session(:chat_token, chat_token) |> get_session()

      {:cont, updated_socket} =
        ChatAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_chat.id == chat.id
    end

    test "redirects to login page if there isn't a valid chat_token", %{conn: conn} do
      chat_token = "invalid_token"
      session = conn |> put_session(:chat_token, chat_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: TodoAppWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = ChatAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_chat == nil
    end

    test "redirects to login page if there isn't a chat_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: TodoAppWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = ChatAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_chat == nil
    end
  end

  describe "on_mount :redirect_if_chat_is_authenticated" do
    test "redirects if there is an authenticated  chat ", %{conn: conn, chat: chat} do
      chat_token = Chats.generate_chat_session_token(chat)
      session = conn |> put_session(:chat_token, chat_token) |> get_session()

      assert {:halt, _updated_socket} =
               ChatAuth.on_mount(
                 :redirect_if_chat_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated chat", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               ChatAuth.on_mount(
                 :redirect_if_chat_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_chat_is_authenticated/2" do
    test "redirects if chat is authenticated", %{conn: conn, chat: chat} do
      conn = conn |> assign(:current_chat, chat) |> ChatAuth.redirect_if_chat_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if chat is not authenticated", %{conn: conn} do
      conn = ChatAuth.redirect_if_chat_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_chat/2" do
    test "redirects if chat is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> ChatAuth.require_authenticated_chat([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/chats/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> ChatAuth.require_authenticated_chat([])

      assert halted_conn.halted
      assert get_session(halted_conn, :chat_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> ChatAuth.require_authenticated_chat([])

      assert halted_conn.halted
      assert get_session(halted_conn, :chat_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> ChatAuth.require_authenticated_chat([])

      assert halted_conn.halted
      refute get_session(halted_conn, :chat_return_to)
    end

    test "does not redirect if chat is authenticated", %{conn: conn, chat: chat} do
      conn = conn |> assign(:current_chat, chat) |> ChatAuth.require_authenticated_chat([])
      refute conn.halted
      refute conn.status
    end
  end
end
