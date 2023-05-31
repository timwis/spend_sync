defmodule SpendSync.TransferLogs.TransferLog do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpendSync.Plans.Plan

  schema "transfer_logs" do
    field :amount, Money.Ecto.Composite.Type
    field :metadata, :map
    field :external_id, Ecto.UUID
    field :status, :string

    belongs_to :plan, Plan

    timestamps()
  end

  @doc false
  def changeset(transfer_log, attrs) do
    transfer_log
    |> cast(attrs, [:external_id, :amount, :metadata, :status])
    |> validate_required([:amount, :status])
  end
end
