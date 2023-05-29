defmodule SpendSync.Repo.Migrations.AddMetadataToTransferLogs do
  use Ecto.Migration

  def change do
    alter table(:transfer_logs) do
      add :metadata, :map
    end
  end
end
