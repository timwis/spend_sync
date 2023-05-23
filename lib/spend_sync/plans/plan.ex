defmodule SpendSync.Plans.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpendSync.Plans.BankAccount
  alias SpendSync.Plans.Mandate
  alias SpendSync.UserAccounts.User

  schema "plans" do
    field :last_synced_at, :utc_datetime
    field :percentage, :integer, default: 100

    belongs_to :user, User
    belongs_to :monitor_account, BankAccount
    belongs_to :mandate, Mandate

    timestamps()
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:last_synced_at, :percentage])
    |> validate_number(:percentage, greater_than: 0, less_than_or_equal_to: 100)
  end
end
