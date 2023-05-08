defmodule SpendSync.Plans.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpendSync.Plans.BankAccount
  alias SpendSync.Plans.Mandate
  alias SpendSync.UserAccounts.User

  schema "plans" do
    field :last_synced_at, :utc_datetime

    belongs_to :user, User
    belongs_to :monitor_account, BankAccount
    belongs_to :mandate, Mandate

    timestamps()
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:last_synced_at])
    |> validate_required([:last_synced_at, :user_id, :monitor_account_id, :mandate_id])
  end
end
