defmodule ElixirLlmWeb.HealthController do
  use ElixirLlmWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
