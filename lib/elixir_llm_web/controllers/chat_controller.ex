defmodule ElixirLlmWeb.ChatController do
  use ElixirLlmWeb, :controller

  alias ElixirLlm.Chat

  def history(conn, %{"session_id" => session_id}) do
    messages = Chat.get_history(session_id)

    json(conn, %{
      session_id: session_id,
      messages: Enum.map(messages, &%{
        role: &1.role,
        content: &1.content,
        timestamp: &1.inserted_at
      })
    })
  end
end
