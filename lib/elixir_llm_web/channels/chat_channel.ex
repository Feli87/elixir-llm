defmodule ElixirLlmWeb.ChatChannel do
  use Phoenix.Channel

  alias ElixirLlm.AI.GeminiWorker
  alias ElixirLlm.AI.RateLimiter
  alias ElixirLlm.Chat

  @impl true
  def join("chat:" <> session_id, _params, socket) do
    history = Chat.get_history(session_id)
    messages = Enum.map(history, &%{role: &1.role, content: &1.content})
    socket = assign(socket, :session_id, session_id)
    {:ok, %{session_id: session_id, history: messages}, socket}
  end

  @impl true
  def handle_in("new_message", %{"content" => content}, socket) do
    user_id = socket.assigns.user_id
    session_id = socket.assigns.session_id

    case RateLimiter.check_rate(user_id) do
      :ok ->
        # Persist user message
        Chat.save_message(session_id, "user", content)

        Task.start(fn ->
          GeminiWorker.stream_response(content, session_id, fn
            {:chunk, text} ->
              push(socket, "ai_chunk", %{text: text})

            {:done, full_response} ->
              Chat.save_message(session_id, "assistant", full_response)
              push(socket, "ai_done", %{text: full_response})

            {:error, reason} ->
              push(socket, "ai_error", %{reason: reason})
          end)
        end)

        {:noreply, socket}

      {:error, :rate_limited} ->
        push(socket, "ai_error", %{reason: "Rate limit exceeded. Please wait."})
        {:noreply, socket}
    end
  end
end
