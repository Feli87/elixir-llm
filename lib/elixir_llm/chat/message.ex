defmodule ElixirLlm.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :session_id, :string
    field :role, :string
    field :content, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:session_id, :role, :content])
    |> validate_required([:session_id, :role, :content])
    |> validate_inclusion(:role, ["user", "assistant"])
  end
end
