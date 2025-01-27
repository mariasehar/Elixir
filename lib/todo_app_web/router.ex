defmodule TodoAppWeb.Router do
  use TodoAppWeb, :router

  import TodoAppWeb.ChatAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TodoAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_chat
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TodoAppWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", TodoAppWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:todo_app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TodoAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", TodoAppWeb do
    pipe_through [:browser, :redirect_if_chat_is_authenticated]

    live_session :redirect_if_chat_is_authenticated,
      on_mount: [{TodoAppWeb.ChatAuth, :redirect_if_chat_is_authenticated}] do
      live "/chats/register", ChatRegistrationLive, :new
      live "/chats/log_in", ChatLoginLive, :new
      live "/chats/reset_password", ChatForgotPasswordLive, :new
      live "/chats/reset_password/:token", ChatResetPasswordLive, :edit

    end

    post "/chats/log_in", ChatSessionController, :create
  end

  scope "/", TodoAppWeb do
    pipe_through [:browser, :require_authenticated_chat]

    live_session :require_authenticated_chat,
      on_mount: [{TodoAppWeb.ChatAuth, :ensure_authenticated}] do
      live "/chats/settings", ChatSettingsLive, :edit
      live "/chats/settings/confirm_email/:token", ChatSettingsLive, :confirm_email
      live "/chat", Live.Index
    end
  end

  scope "/", TodoAppWeb do
    pipe_through [:browser]

    delete "/chats/log_out", ChatSessionController, :delete

    live_session :current_chat,
      on_mount: [{TodoAppWeb.ChatAuth, :mount_current_chat}] do
      live "/chats/confirm/:token", ChatConfirmationLive, :edit
      live "/chats/confirm", ChatConfirmationInstructionsLive, :new
    end
  end
end
