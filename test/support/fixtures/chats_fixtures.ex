defmodule TodoApp.ChatsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TodoApp.Chats` context.
  """

  def unique_chat_email, do: "chat#{System.unique_integer()}@example.com"
  def valid_chat_password, do: "hello world!"

  def valid_chat_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_chat_email(),
      password: valid_chat_password()
    })
  end

  def chat_fixture(attrs \\ %{}) do
    {:ok, chat} =
      attrs
      |> valid_chat_attributes()
      |> TodoApp.Chats.register_chat()

    chat
  end

  def extract_chat_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
