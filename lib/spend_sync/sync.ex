defmodule SpendSync.Sync do
  @moduledoc """
  The Sync context.
  """

  require Logger
  import Ecto.Query, warn: false

  alias SpendSync.Plans
  alias SpendSync.Plans.Plan
  alias SpendSync.Plans.BankConnection
  alias SpendSync.Plans.BankAccount
  alias SpendSync.TransferLogs

  def perform_sync(%Plan{} = plan) do
    since = plan.last_synced_at || one_day_ago()

    with {:ok, transactions} = get_transactions(plan.monitor_account, since),
         raw_sum <- sum_transactions(transactions),
         amount_to_transfer <- calculate_amount_to_transfer(raw_sum, plan.percentage) do
      {:ok, payment} = transfer_funds(amount_to_transfer, plan.mandate, plan.status)
      {:ok, _plan} = Plans.update_plan(plan, %{last_synced_at: DateTime.utc_now()})

      TransferLogs.create_transfer_log(plan, %{
        external_id: payment["id"],
        amount: amount_to_transfer,
        status: payment["status"],
        metadata: %{
          "transactions" => transactions,
          "raw_sum" => raw_sum,
          "since" => since
        }
      })
    end
  end

  # raw_sum would be positive when, for example, refunds were greater than spend
  defp calculate_amount_to_transfer(%Money{amount: amount}, _percentage) when amount > 0 do
    Money.new(0)
  end

  defp calculate_amount_to_transfer(%Money{} = raw_sum, percentage) do
    raw_sum
    |> Money.abs()
    |> Money.multiply(percentage / 100)
  end

  defp one_day_ago() do
    DateTime.add(DateTime.utc_now(), -1, :day)
  end

  defp get_transactions(
         %BankAccount{} = bank_account,
         %DateTime{} = since
       ) do
    # TODO: Only renew if expired
    with {:ok, bank_connection} <- renew_connection(bank_account.bank_connection),
         {:ok, transactions} <-
           TrueLayer.get_card_transactions(
             bank_connection,
             bank_account.external_account_id,
             since
           ) do
      {:ok, transactions}
    end
  end

  defp renew_connection(%BankConnection{} = bank_connection) do
    with {:ok, renewed_token} <- TrueLayer.renew_token(bank_connection.refresh_token),
         {:ok, renewed_connection} <-
           Plans.update_bank_connection(bank_connection, Map.from_struct(renewed_token)) do
      {:ok, renewed_connection}
    end
  end

  defp sum_transactions(transactions) do
    Enum.reduce(transactions, Money.new(0), fn txn, acc -> Money.add(acc, txn.amount) end)
  end

  defp transfer_funds(_amount, _mandate, :simulation) do
    {:ok, %{"id" => nil, "status" => "simulation"}}
  end

  defp transfer_funds(%Money{amount: amount}, _mandate, :live) when amount == 0 do
    {:ok, %{"id" => nil, "status" => "zero"}}
  end

  defp transfer_funds(%Money{} = amount_to_transfer, mandate, :live) do
    TrueLayer.create_payment_on_mandate(mandate.external_id, amount_to_transfer)
  end
end
