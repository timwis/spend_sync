defmodule SpendSync.Repo.Migrations.CreateBankAccounts do
  use Ecto.Migration

  def change do
    create table(:bank_accounts) do
      add :account_type, :string, null: false
      add :external_account_id, :string, null: false
      add :display_name, :string, null: false
      add :bank_connection_id, references(:bank_connections, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:bank_accounts, [:bank_connection_id])
  end
end
