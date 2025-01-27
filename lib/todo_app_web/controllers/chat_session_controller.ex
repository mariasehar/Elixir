defmodule TodoAppWeb.ChatSessionController do
  use TodoAppWeb, :controller

  alias TodoApp.Chats
  alias TodoAppWeb.ChatAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:chat_return_to, ~p"/chats/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"chat" => chat_params}, info) do
    %{"email" => email, "password" => password} = chat_params

    if chat = Chats.get_chat_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> ChatAuth.log_in_chat(chat, chat_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/chats/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> ChatAuth.log_out_chat()
  end
end
