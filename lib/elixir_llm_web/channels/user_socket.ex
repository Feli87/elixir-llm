defmodule ElixirLlmWeb.UserSocket do
  use Phoenix.Socket

  channel "chat:*", ElixirLlmWeb.ChatChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    # TODO: validate token and extract user_id
    # For MVP, accept any connection with a token
    {:ok, assign(socket, :user_id, token)}
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
