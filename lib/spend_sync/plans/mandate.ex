defmodule SpendSync.Plans.Mandate do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpendSync.UserAccounts.User

  schema "mandates" do
    field :external_id, Ecto.UUID

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(mandate, attrs) do
    mandate
    |> cast(attrs, [:external_id])
    |> validate_required([:external_id])
  end
end
