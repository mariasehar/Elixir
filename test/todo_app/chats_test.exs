defmodule TodoApp.ChatsTest do
  use TodoApp.DataCase

  alias TodoApp.Chats

  import TodoApp.ChatsFixtures
  alias TodoApp.Chats.{Chat, ChatToken}

  describe "get_chat_by_email/1" do
    test "does not return the chat if the email does not exist" do
      refute Chats.get_chat_by_email("unknown@example.com")
    end

    test "returns the chat if the email exists" do
      %{id: id} = chat = chat_fixture()
      assert %Chat{id: ^id} = Chats.get_chat_by_email(chat.email)
    end
  end

  describe "get_chat_by_email_and_password/2" do
    test "does not return the chat if the email does not exist" do
      refute Chats.get_chat_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the chat if the password is not valid" do
      chat = chat_fixture()
      refute Chats.get_chat_by_email_and_password(chat.email, "invalid")
    end

    test "returns the chat if the email and password are valid" do
      %{id: id} = chat = chat_fixture()

      assert %Chat{id: ^id} =
               Chats.get_chat_by_email_and_password(chat.email, valid_chat_password())
    end
  end

  describe "get_chat!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Chats.get_chat!(-1)
      end
    end

    test "returns the chat with the given id" do
      %{id: id} = chat = chat_fixture()
      assert %Chat{id: ^id} = Chats.get_chat!(chat.id)
    end
  end

  describe "register_chat/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Chats.register_chat(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Chats.register_chat(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Chats.register_chat(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = chat_fixture()
      {:error, changeset} = Chats.register_chat(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Chats.register_chat(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers chats with a hashed password" do
      email = unique_chat_email()
      {:ok, chat} = Chats.register_chat(valid_chat_attributes(email: email))
      assert chat.email == email
      assert is_binary(chat.hashed_password)
      assert is_nil(chat.confirmed_at)
      assert is_nil(chat.password)
    end
  end

  describe "change_chat_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Chats.change_chat_registration(%Chat{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_chat_email()
      password = valid_chat_password()

      changeset =
        Chats.change_chat_registration(
          %Chat{},
          valid_chat_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_chat_email/2" do
    test "returns a chat changeset" do
      assert %Ecto.Changeset{} = changeset = Chats.change_chat_email(%Chat{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_chat_email/3" do
    setup do
      %{chat: chat_fixture()}
    end

    test "requires email to change", %{chat: chat} do
      {:error, changeset} = Chats.apply_chat_email(chat, valid_chat_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{chat: chat} do
      {:error, changeset} =
        Chats.apply_chat_email(chat, valid_chat_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{chat: chat} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Chats.apply_chat_email(chat, valid_chat_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{chat: chat} do
      %{email: email} = chat_fixture()
      password = valid_chat_password()

      {:error, changeset} = Chats.apply_chat_email(chat, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{chat: chat} do
      {:error, changeset} =
        Chats.apply_chat_email(chat, "invalid", %{email: unique_chat_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{chat: chat} do
      email = unique_chat_email()
      {:ok, chat} = Chats.apply_chat_email(chat, valid_chat_password(), %{email: email})
      assert chat.email == email
      assert Chats.get_chat!(chat.id).email != email
    end
  end

  describe "deliver_chat_update_email_instructions/3" do
    setup do
      %{chat: chat_fixture()}
    end

    test "sends token through notification", %{chat: chat} do
      token =
        extract_chat_token(fn url ->
          Chats.deliver_chat_update_email_instructions(chat, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert chat_token = Repo.get_by(ChatToken, token: :crypto.hash(:sha256, token))
      assert chat_token.chat_id == chat.id
      assert chat_token.sent_to == chat.email
      assert chat_token.context == "change:current@example.com"
    end
  end

  describe "update_chat_email/2" do
    setup do
      chat = chat_fixture()
      email = unique_chat_email()

      token =
        extract_chat_token(fn url ->
          Chats.deliver_chat_update_email_instructions(%{chat | email: email}, chat.email, url)
        end)

      %{chat: chat, token: token, email: email}
    end

    test "updates the email with a valid token", %{chat: chat, token: token, email: email} do
      assert Chats.update_chat_email(chat, token) == :ok
      changed_chat = Repo.get!(Chat, chat.id)
      assert changed_chat.email != chat.email
      assert changed_chat.email == email
      assert changed_chat.confirmed_at
      assert changed_chat.confirmed_at != chat.confirmed_at
      refute Repo.get_by(ChatToken, chat_id: chat.id)
    end

    test "does not update email with invalid token", %{chat: chat} do
      assert Chats.update_chat_email(chat, "oops") == :error
      assert Repo.get!(Chat, chat.id).email == chat.email
      assert Repo.get_by(ChatToken, chat_id: chat.id)
    end

    test "does not update email if chat email changed", %{chat: chat, token: token} do
      assert Chats.update_chat_email(%{chat | email: "current@example.com"}, token) == :error
      assert Repo.get!(Chat, chat.id).email == chat.email
      assert Repo.get_by(ChatToken, chat_id: chat.id)
    end

    test "does not update email if token expired", %{chat: chat, token: token} do
      {1, nil} = Repo.update_all(ChatToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Chats.update_chat_email(chat, token) == :error
      assert Repo.get!(Chat, chat.id).email == chat.email
      assert Repo.get_by(ChatToken, chat_id: chat.id)
    end
  end

  describe "change_chat_password/2" do
    test "returns a chat changeset" do
      assert %Ecto.Changeset{} = changeset = Chats.change_chat_password(%Chat{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Chats.change_chat_password(%Chat{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_chat_password/3" do
    setup do
      %{chat: chat_fixture()}
    end

    test "validates password", %{chat: chat} do
      {:error, changeset} =
        Chats.update_chat_password(chat, valid_chat_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{chat: chat} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Chats.update_chat_password(chat, valid_chat_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{chat: chat} do
      {:error, changeset} =
        Chats.update_chat_password(chat, "invalid", %{password: valid_chat_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{chat: chat} do
      {:ok, chat} =
        Chats.update_chat_password(chat, valid_chat_password(), %{
          password: "new valid password"
        })

      assert is_nil(chat.password)
      assert Chats.get_chat_by_email_and_password(chat.email, "new valid password")
    end

    test "deletes all tokens for the given chat", %{chat: chat} do
      _ = Chats.generate_chat_session_token(chat)

      {:ok, _} =
        Chats.update_chat_password(chat, valid_chat_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(ChatToken, chat_id: chat.id)
    end
  end

  describe "generate_chat_session_token/1" do
    setup do
      %{chat: chat_fixture()}
    end

    test "generates a token", %{chat: chat} do
      token = Chats.generate_chat_session_token(chat)
      assert chat_token = Repo.get_by(ChatToken, token: token)
      assert chat_token.context == "session"

      # Creating the same token for another chat should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%ChatToken{
          token: chat_token.token,
          chat_id: chat_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_chat_by_session_token/1" do
    setup do
      chat = chat_fixture()
      token = Chats.generate_chat_session_token(chat)
      %{chat: chat, token: token}
    end

    test "returns chat by token", %{chat: chat, token: token} do
      assert session_chat = Chats.get_chat_by_session_token(token)
      assert session_chat.id == chat.id
    end

    test "does not return chat for invalid token" do
      refute Chats.get_chat_by_session_token("oops")
    end

    test "does not return chat for expired token", %{token: token} do
      {1, nil} = Repo.update_all(ChatToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Chats.get_chat_by_session_token(token)
    end
  end

  describe "delete_chat_session_token/1" do
    test "deletes the token" do
      chat = chat_fixture()
      token = Chats.generate_chat_session_token(chat)
      assert Chats.delete_chat_session_token(token) == :ok
      refute Chats.get_chat_by_session_token(token)
    end
  end

  describe "deliver_chat_confirmation_instructions/2" do
    setup do
      %{chat: chat_fixture()}
    end

    test "sends token through notification", %{chat: chat} do
      token =
        extract_chat_token(fn url ->
          Chats.deliver_chat_confirmation_instructions(chat, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert chat_token = Repo.get_by(ChatToken, token: :crypto.hash(:sha256, token))
      assert chat_token.chat_id == chat.id
      assert chat_token.sent_to == chat.email
      assert chat_token.context == "confirm"
    end
  end

  describe "confirm_chat/1" do
    setup do
      chat = chat_fixture()

      token =
        extract_chat_token(fn url ->
          Chats.deliver_chat_confirmation_instructions(chat, url)
        end)

      %{chat: chat, token: token}
    end

    test "confirms the email with a valid token", %{chat: chat, token: token} do
      assert {:ok, confirmed_chat} = Chats.confirm_chat(token)
      assert confirmed_chat.confirmed_at
      assert confirmed_chat.confirmed_at != chat.confirmed_at
      assert Repo.get!(Chat, chat.id).confirmed_at
      refute Repo.get_by(ChatToken, chat_id: chat.id)
    end

    test "does not confirm with invalid token", %{chat: chat} do
      assert Chats.confirm_chat("oops") == :error
      refute Repo.get!(Chat, chat.id).confirmed_at
      assert Repo.get_by(ChatToken, chat_id: chat.id)
    end

    test "does not confirm email if token expired", %{chat: chat, token: token} do
      {1, nil} = Repo.update_all(ChatToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Chats.confirm_chat(token) == :error
      refute Repo.get!(Chat, chat.id).confirmed_at
      assert Repo.get_by(ChatToken, chat_id: chat.id)
    end
  end

  describe "deliver_chat_reset_password_instructions/2" do
    setup do
      %{chat: chat_fixture()}
    end

    test "sends token through notification", %{chat: chat} do
      token =
        extract_chat_token(fn url ->
          Chats.deliver_chat_reset_password_instructions(chat, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert chat_token = Repo.get_by(ChatToken, token: :crypto.hash(:sha256, token))
      assert chat_token.chat_id == chat.id
      assert chat_token.sent_to == chat.email
      assert chat_token.context == "reset_password"
    end
  end

  describe "get_chat_by_reset_password_token/1" do
    setup do
      chat = chat_fixture()

      token =
        extract_chat_token(fn url ->
          Chats.deliver_chat_reset_password_instructions(chat, url)
        end)

      %{chat: chat, token: token}
    end

    test "returns the chat with valid token", %{chat: %{id: id}, token: token} do
      assert %Chat{id: ^id} = Chats.get_chat_by_reset_password_token(token)
      assert Repo.get_by(ChatToken, chat_id: id)
    end

    test "does not return the chat with invalid token", %{chat: chat} do
      refute Chats.get_chat_by_reset_password_token("oops")
      assert Repo.get_by(ChatToken, chat_id: chat.id)
    end

    test "does not return the chat if token expired", %{chat: chat, token: token} do
      {1, nil} = Repo.update_all(ChatToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Chats.get_chat_by_reset_password_token(token)
      assert Repo.get_by(ChatToken, chat_id: chat.id)
    end
  end

  describe "reset_chat_password/2" do
    setup do
      %{chat: chat_fixture()}
    end

    test "validates password", %{chat: chat} do
      {:error, changeset} =
        Chats.reset_chat_password(chat, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{chat: chat} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Chats.reset_chat_password(chat, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{chat: chat} do
      {:ok, updated_chat} = Chats.reset_chat_password(chat, %{password: "new valid password"})
      assert is_nil(updated_chat.password)
      assert Chats.get_chat_by_email_and_password(chat.email, "new valid password")
    end

    test "deletes all tokens for the given chat", %{chat: chat} do
      _ = Chats.generate_chat_session_token(chat)
      {:ok, _} = Chats.reset_chat_password(chat, %{password: "new valid password"})
      refute Repo.get_by(ChatToken, chat_id: chat.id)
    end
  end

  describe "inspect/2 for the Chat module" do
    test "does not include password" do
      refute inspect(%Chat{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
