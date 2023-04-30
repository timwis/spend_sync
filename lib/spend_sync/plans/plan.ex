defmodule SpendSync.Plans.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpendSync.Plans.BankAccount
  alias SpendSync.UserAccounts.User

  schema "plans" do
    field :last_synced_at, :utc_datetime
    # field :user_id, :id
    # field :monitor_account_id, :id
    # field :source_account_id, :id
    # field :destination_account_id, :id

    belongs_to :user, User
    belongs_to :monitor_account, BankAccount
    belongs_to :source_account, BankAccount
    belongs_to :destination_account, BankAccount

    timestamps()
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:last_synced_at])
    |> validate_required([:last_synced_at, :user_id, :monitor_account_id, :source_account_id, :destination_account_id])
  end
end
