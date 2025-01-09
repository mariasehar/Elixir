defmodule TodoAppWeb.Live.Show do
  use TodoAppWeb, :live_component


  def update(assigns,socket) do
    {:ok, socket |>assign(assigns)}
  end

end
