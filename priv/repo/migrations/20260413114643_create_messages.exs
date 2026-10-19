defmodule ElixirLlm.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :session_id, :string, null: false
      add :role, :string, null: false
      add :content, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:session_id])
  end
end
