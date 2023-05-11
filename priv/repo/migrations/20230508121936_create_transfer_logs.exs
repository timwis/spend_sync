defmodule SpendSync.Repo.Migrations.CreateTransferLogs do
  use Ecto.Migration

  def change do
    create table(:transfer_logs) do
      add :external_id, :uuid, null: false
      add :amount, :money_with_currency, null: false
      add :status, :string, null: false
      add :plan_id, references(:plans, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:transfer_logs, [:plan_id])
  end
end
