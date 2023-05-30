defmodule SpendSync.Repo.Migrations.AddStatusToPlans do
  use Ecto.Migration

  def change do
    alter table(:plans) do
      add :status, :string
    end
  end
end
