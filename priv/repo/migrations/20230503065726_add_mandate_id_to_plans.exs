defmodule SpendSync.Repo.Migrations.AddMandateIdToPlans do
  use Ecto.Migration

  def up do
    alter table("plans") do
      add :mandate_id, references(:mandates, on_delete: :nothing), null: false, default: 1
      remove :source_account_id
      remove :destination_account_id
    end

    create index(:plans, [:mandate_id])
  end

  def down do
    alter table("plans") do
      remove :mandate_id
      add :source_account_id, references(:bank_accounts, on_delete: :nothing), null: false
      add :destination_account_id, references(:bank_accounts, on_delete: :nothing), null: false
    end

    create index(:plans, [:source_account_id])
    create index(:plans, [:destination_account_id])
  end
end
