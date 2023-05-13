defmodule SpendSync.Repo.Migrations.AddPercentageToPlan do
  use Ecto.Migration

  def change do
    alter table(:plans) do
      add :percentage, :integer, default: 100, null: false
    end

    create constraint(:plans, :valid_percentage, check: "percentage > 0 and percentage <= 100")
  end
end
