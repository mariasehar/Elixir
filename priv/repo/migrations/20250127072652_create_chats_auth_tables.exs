defmodule TodoApp.Repo.Migrations.CreateChatsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:chats) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:chats, [:email])

    create table(:chats_tokens) do
      add :chat_id, references(:chats, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:chats_tokens, [:chat_id])
    create unique_index(:chats_tokens, [:context, :token])
  end
end
