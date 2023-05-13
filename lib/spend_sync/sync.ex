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
    with {:ok, transactions} <- get_transactions(plan.monitor_account, plan.last_synced_at),
         sum <- sum_transactions(transactions),
         :ok <- should_transfer?(sum),
         positive_sum <- Money.abs(sum),
         amount_to_transfer <- percent_of(positive_sum, plan.percentage),
         {:ok, %{"id" => payment_id}} <- transfer_funds(amount_to_transfer, plan.mandate) do
      {:ok, _plan} = Plans.update_plan(plan, %{last_synced_at: DateTime.utc_now()})

      TransferLogs.create_transfer_log(plan, %{
        external_id: payment_id,
        amount: positive_sum,
        status: "authorizing"
      })
    else
      {:error, :non_negative} ->
        {:ok, _plan} = Plans.update_plan(plan, %{last_synced_at: DateTime.utc_now()})
        {:ok, :non_negative}
    end
  end

  defp should_transfer?(%Money{} = amount) do
    if Money.negative?(amount), do: :ok, else: {:error, :non_negative}
  end

  defp percent_of(%Money{} = amount, percentage) do
    Money.multiply(amount, percentage / 100)
  end

  defp get_transactions(%BankAccount{} = bank_account, nil) do
    get_transactions(bank_account, DateTime.add(DateTime.utc_now(), -1, :day))
  end

  defp get_transactions(
         %BankAccount{} = bank_account,
         %DateTime{} = since
       ) do
    # {:ok, bank_connection} =
    #   if AccessToken.expired?(bank_account.bank_connection) do
    #     renew_connection(bank_account.bank_connection)
    #   else
    #     {:ok, bank_account.bank_connection}
    #   end

    # {:ok, TrueLayer.get_card_transactions(bank_connection, bank_account.external_account_id, since)}

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

  defp transfer_funds(amount, mandate) do
    TrueLayer.create_payment_on_mandate(mandate.external_id, amount)
  end
end
