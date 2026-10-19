defmodule ElixirLlmWeb.Router do
  use ElixirLlmWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ElixirLlmWeb do
    pipe_through :api

    get "/health", HealthController, :index
    get "/chat/:session_id/history", ChatController, :history
  end

  # SPA catch-all: serve React index.html for any non-API route
  scope "/", ElixirLlmWeb do
    get "/*path", FallbackController, :index
  end
end
