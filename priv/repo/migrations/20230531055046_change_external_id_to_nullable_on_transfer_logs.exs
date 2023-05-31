defmodule SpendSync.Repo.Migrations.ChangeExternalIdToNullableOnTransferLogs do
  use Ecto.Migration

  def change do
    alter table(:transfer_logs) do
      modify :external_id, :uuid, null: true, from: {:uuid, null: false}
    end
  end
end
