defmodule SpendSync.UserAccounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpendSync.Plans.BankConnection
  alias SpendSync.Plans.Plan

  schema "users" do
    field :email, :string

    has_many :bank_connections, BankConnection
    has_many :plans, Plan

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
  end
end
