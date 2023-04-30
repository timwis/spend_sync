defmodule SpendSync.Plans.BankAccount do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpendSync.Plans.BankConnection

  schema "bank_accounts" do
    field :account_type, :string
    field :display_name, :string
    field :external_account_id, :string
    # field :bank_connection_id, :id

    belongs_to :bank_connection, BankConnection

    timestamps()
  end

  @doc false
  def changeset(bank_account, attrs) do
    bank_account
    |> cast(attrs, [:account_type, :external_account_id, :display_name])
    |> validate_required([:account_type, :external_account_id, :display_name, :bank_connection_id])
  end
end
