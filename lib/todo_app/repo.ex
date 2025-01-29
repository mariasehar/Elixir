defmodule TodoApp.Repo do
  use Ecto.Repo,
    otp_app: :todo_app,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 5
end
