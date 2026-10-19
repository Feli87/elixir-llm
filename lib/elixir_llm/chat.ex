defmodule ElixirLlm.Chat do
  @moduledoc """
  Context module for chat operations.
  """
  import Ecto.Query
  alias ElixirLlm.Repo
  alias ElixirLlm.Chat.Message

  def save_message(session_id, role, content) do
    %Message{}
    |> Message.changeset(%{session_id: session_id, role: role, content: content})
    |> Repo.insert()
  end

  def get_history(session_id, limit \\ 50) do
    Message
    |> where([m], m.session_id == ^session_id)
    |> order_by([m], asc: m.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end
end
