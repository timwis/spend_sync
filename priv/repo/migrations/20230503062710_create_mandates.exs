defmodule SpendSync.Repo.Migrations.CreateMandates do
  use Ecto.Migration

  def change do
    create table(:mandates) do
      add :external_id, :uuid, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:mandates, [:user_id])
  end
end
