defmodule ElixirLlm.Repo do
  use Ecto.Repo,
    otp_app: :elixir_llm,
    adapter: Ecto.Adapters.Postgres
end
