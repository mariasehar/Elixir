defmodule TodoAppWeb.Live.ShowTodo do
  use TodoAppWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
