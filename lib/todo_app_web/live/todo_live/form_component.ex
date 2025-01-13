defmodule TodoAppWeb.TodoLive.FormComponent do
  use TodoAppWeb, :live_component

  alias TodoApp.Todos

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage todo records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="todo-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:status]} type="text" label="Status" />
    <div :if={@todo.image}>
    <img
          src={@todo.image}
          alt="uploaded image"
           style="width: 100px; height: 100px; object-fit: cover;"
            /> </div>

        <.live_file_input upload={@uploads.image}/>
        <section phx-drop-target={@uploads.image.ref}>
        <article :for={entry <- @uploads.image.entries} class="upload-entry">

        <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} aria-label="cancel" class="text-red-800">Cancel Upload</button>
        <p :for={err <- upload_errors(@uploads.image, entry)} class="alert alert-danger">{error_to_string(err)}</p>
        </article>

        <p :for={err <- upload_errors(@uploads.image)} class="alert alert-danger">
        {error_to_string(err)}
       </p>


        </section>
        <:actions>
          <.button phx-disable-with="Saving...">Save Todo</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{todo: todo} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:uploaded_files, [])
     |> allow_upload(:image, accept: ~w(.jpg .png .jpeg), max_entries: 1)
     |> assign_new(:form, fn ->
     to_form(Todos.change_todo(todo))


     end)}
  end
    defp error_to_string(:too_large), do: "Error:Too large"
    defp error_to_string(:not_accepted), do: "Error:You have selected an unacceptable file type"
  @impl true
  def handle_event("validate", %{"todo" => todo_params}, socket) do
    changeset = Todos.change_todo(socket.assigns.todo, todo_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"todo" => todo_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        dest = Path.join(Application.app_dir(:todo_app, "priv/static/uploads"), Path.basename(path))
        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
    new_todo_params = Map.put(todo_params, "image", List.first(uploaded_files))

    save_todo(socket, socket.assigns.action, new_todo_params)
  end
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  defp save_todo(socket, :edit, todo_params) do
    IO.inspect(todo_params, label: "saved todo")
    case  Todos.update_todo(socket.assigns.todo, todo_params) do
      {:ok, todo} ->
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "topic",{:todo, todo} )

        notify_parent({:saved, todo})

        {:noreply,
         socket
         |> put_flash(:info, "Todo updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_todo(socket, :new, todo_params) do
    case Todos.create_todo(todo_params) do
      {:ok, todo} ->
        Phoenix.PubSub.broadcast(TodoApp.PubSub, "topic",{:todo, todo} )

        notify_parent({:saved, todo})

        {:noreply,
         socket
         |> put_flash(:info, "Todo created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
