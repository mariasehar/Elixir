defmodule TodoAppWeb.TodoLive.Show do
  use TodoAppWeb, :live_component


  @impl true
  def update(assigns, socket) do
    {:ok, socket
  |> assign(assigns)}
  end



end
