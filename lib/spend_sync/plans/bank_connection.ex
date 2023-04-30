defmodule SpendSync.Plans.BankConnection do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpendSync.Encrypted.Binary
  alias SpendSync.UserAccounts.User
  alias SpendSync.Plans.BankAccount

  schema "bank_connections" do
    field :access_token, Binary
    field :expires_at, :utc_datetime
    field :provider, :string
    field :refresh_token, Binary
    # field :user_id, :id

    belongs_to :user, User
    has_many :bank_accounts, BankAccount

    timestamps()
  end

  @doc false
  def changeset(bank_connection, attrs) do
    bank_connection
    |> cast(attrs, [:provider, :access_token, :expires_at, :refresh_token])
    |> validate_required([:provider, :access_token, :expires_at, :refresh_token])
    # |> assoc_constraint(:user)
  end

  def expired?(%{expires_at: expires_at}) do
    expires_at < DateTime.utc_now()
  end
end
