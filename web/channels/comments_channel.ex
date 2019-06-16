defmodule Discuss.CommentsChannel do
  use Discuss.Web, :channel
  alias Discuss.{Topic, Comment}

  def join("comments:" <> id, _params, socket) do
    id = String.to_integer(id)
    topic = Topic
      |> Repo.get(id)
      |> Repo.preload(comments: [:user])

    {:ok, %{comments: topic.comments}, assign(socket, :topic, topic)}
  end

  def handle_in(name, %{"content" => content}, socket) do
    topic = socket.assigns.topic
    user_id = socket.assigns.user_id

    changeset = topic
      |> build_assoc(:comments, user_id: user_id)
      |> Comment.changeset(%{content: content})

    case Repo.insert(changeset) do
      {:ok, comment} ->
        broadcast!(socket, "comments:#{socket.assigns.topic.id}:new", %{comment: comment})
        {:reply, :ok, :socket}
      {:error, _reason} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end
end
