defmodule SpendSync.Repo.Migrations.CreatePlans do
  use Ecto.Migration

  def change do
    create table(:plans) do
      add :last_synced_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :monitor_account_id, references(:bank_accounts, on_delete: :nothing), null: false
      add :source_account_id, references(:bank_accounts, on_delete: :nothing), null: false
      add :destination_account_id, references(:bank_accounts, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:plans, [:user_id])
    create index(:plans, [:monitor_account_id])
    create index(:plans, [:source_account_id])
    create index(:plans, [:destination_account_id])
  end
end
