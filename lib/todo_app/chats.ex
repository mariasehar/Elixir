defmodule TodoApp.Chats do
  @moduledoc """
  The Chats context.
  """

  import Ecto.Query, warn: false
  alias TodoApp.Repo

  alias TodoApp.Chats.{Chat, ChatToken, ChatNotifier}

  ## Database getters

  @doc """
  Gets a chat by email.

  ## Examples

      iex> get_chat_by_email("foo@example.com")
      %Chat{}

      iex> get_chat_by_email("unknown@example.com")
      nil

  """
  def get_chat_by_email(email) when is_binary(email) do
    Repo.get_by(Chat, email: email)
  end

  @doc """
  Gets a chat by email and password.

  ## Examples

      iex> get_chat_by_email_and_password("foo@example.com", "correct_password")
      %Chat{}

      iex> get_chat_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_chat_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    chat = Repo.get_by(Chat, email: email)
    if Chat.valid_password?(chat, password), do: chat
  end

  @doc """
  Gets a single chat.

  Raises `Ecto.NoResultsError` if the Chat does not exist.

  ## Examples

      iex> get_chat!(123)
      %Chat{}

      iex> get_chat!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat!(id), do: Repo.get!(Chat, id)

  ## Chat registration

  @doc """
  Registers a chat.

  ## Examples

      iex> register_chat(%{field: value})
      {:ok, %Chat{}}

      iex> register_chat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_chat(attrs) do
    %Chat{}
    |> Chat.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat changes.

  ## Examples

      iex> change_chat_registration(chat)
      %Ecto.Changeset{data: %Chat{}}

  """
  def change_chat_registration(%Chat{} = chat, attrs \\ %{}) do
    Chat.registration_changeset(chat, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the chat email.

  ## Examples

      iex> change_chat_email(chat)
      %Ecto.Changeset{data: %Chat{}}

  """
  def change_chat_email(chat, attrs \\ %{}) do
    Chat.email_changeset(chat, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_chat_email(chat, "valid password", %{email: ...})
      {:ok, %Chat{}}

      iex> apply_chat_email(chat, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_chat_email(chat, password, attrs) do
    chat
    |> Chat.email_changeset(attrs)
    |> Chat.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the chat email using the given token.

  If the token matches, the chat email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_chat_email(chat, token) do
    context = "change:#{chat.email}"

    with {:ok, query} <- ChatToken.verify_change_email_token_query(token, context),
         %ChatToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(chat_email_multi(chat, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp chat_email_multi(chat, email, context) do
    changeset =
      chat
      |> Chat.email_changeset(%{email: email})
      |> Chat.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:chat, changeset)
    |> Ecto.Multi.delete_all(:tokens, ChatToken.by_chat_and_contexts_query(chat, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given chat.

  ## Examples

      iex> deliver_chat_update_email_instructions(chat, current_email, &url(~p"/chats/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_chat_update_email_instructions(%Chat{} = chat, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, chat_token} = ChatToken.build_email_token(chat, "change:#{current_email}")

    Repo.insert!(chat_token)
    ChatNotifier.deliver_update_email_instructions(chat, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the chat password.

  ## Examples

      iex> change_chat_password(chat)
      %Ecto.Changeset{data: %Chat{}}

  """
  def change_chat_password(chat, attrs \\ %{}) do
    Chat.password_changeset(chat, attrs, hash_password: false)
  end

  @doc """
  Updates the chat password.

  ## Examples

      iex> update_chat_password(chat, "valid password", %{password: ...})
      {:ok, %Chat{}}

      iex> update_chat_password(chat, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat_password(chat, password, attrs) do
    changeset =
      chat
      |> Chat.password_changeset(attrs)
      |> Chat.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:chat, changeset)
    |> Ecto.Multi.delete_all(:tokens, ChatToken.by_chat_and_contexts_query(chat, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{chat: chat}} -> {:ok, chat}
      {:error, :chat, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_chat_session_token(chat) do
    {token, chat_token} = ChatToken.build_session_token(chat)
    Repo.insert!(chat_token)
    token
  end

  @doc """
  Gets the chat with the given signed token.
  """
  def get_chat_by_session_token(token) do
    {:ok, query} = ChatToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_chat_session_token(token) do
    Repo.delete_all(ChatToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given chat.

  ## Examples

      iex> deliver_chat_confirmation_instructions(chat, &url(~p"/chats/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_chat_confirmation_instructions(confirmed_chat, &url(~p"/chats/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_chat_confirmation_instructions(%Chat{} = chat, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if chat.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, chat_token} = ChatToken.build_email_token(chat, "confirm")
      Repo.insert!(chat_token)
      ChatNotifier.deliver_confirmation_instructions(chat, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a chat by the given token.

  If the token matches, the chat account is marked as confirmed
  and the token is deleted.
  """
  def confirm_chat(token) do
    with {:ok, query} <- ChatToken.verify_email_token_query(token, "confirm"),
         %Chat{} = chat <- Repo.one(query),
         {:ok, %{chat: chat}} <- Repo.transaction(confirm_chat_multi(chat)) do
      {:ok, chat}
    else
      _ -> :error
    end
  end

  defp confirm_chat_multi(chat) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:chat, Chat.confirm_changeset(chat))
    |> Ecto.Multi.delete_all(:tokens, ChatToken.by_chat_and_contexts_query(chat, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given chat.

  ## Examples

      iex> deliver_chat_reset_password_instructions(chat, &url(~p"/chats/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_chat_reset_password_instructions(%Chat{} = chat, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, chat_token} = ChatToken.build_email_token(chat, "reset_password")
    Repo.insert!(chat_token)
    ChatNotifier.deliver_reset_password_instructions(chat, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the chat by reset password token.

  ## Examples

      iex> get_chat_by_reset_password_token("validtoken")
      %Chat{}

      iex> get_chat_by_reset_password_token("invalidtoken")
      nil

  """
  def get_chat_by_reset_password_token(token) do
    with {:ok, query} <- ChatToken.verify_email_token_query(token, "reset_password"),
         %Chat{} = chat <- Repo.one(query) do
      chat
    else
      _ -> nil
    end
  end

  @doc """
  Resets the chat password.

  ## Examples

      iex> reset_chat_password(chat, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Chat{}}

      iex> reset_chat_password(chat, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_chat_password(chat, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:chat, Chat.password_changeset(chat, attrs))
    |> Ecto.Multi.delete_all(:tokens, ChatToken.by_chat_and_contexts_query(chat, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{chat: chat}} -> {:ok, chat}
      {:error, :chat, changeset, _} -> {:error, changeset}
    end
  end
end
