defmodule SpendSync.Repo.Migrations.CreateBankConnections do
  use Ecto.Migration

  def change do
    create table(:bank_connections) do
      add :provider, :string, null: false
      add :access_token, :binary, null: false
      add :expires_at, :utc_datetime, null: false
      add :refresh_token, :binary, null: false
      # add :key_id, :uuid, null: false, default: fragment("(pgsodium.create_key()).id")
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:bank_connections, [:user_id])
  end
end
