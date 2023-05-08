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

  def perform_sync(%Plan{
        monitor_account: monitor_account,
        mandate: mandate,
        last_synced_at: last_synced_at
      } = plan) do
    with {:ok, transactions} <- get_transactions(monitor_account, last_synced_at),
         sum <- sum_transactions(transactions),
         {:ok, _sum} <- should_transfer?(sum),
         positive_sum <- Money.abs(sum),
         {:ok, sum_transferred} <- transfer_funds(positive_sum, mandate)
    do
      {:ok, _plan} = Plans.update_plan(plan, %{last_synced_at: DateTime.utc_now()})
      {:ok, sum_transferred}
    else
      {:error, :non_negative} ->
        {:ok, _plan} = Plans.update_plan(plan, %{last_synced_at: DateTime.utc_now()})
        {:noop, :non_negative}
    end
  end

  defp should_transfer?(%Money{} = amount) do
    if Money.negative?(amount), do: {:ok, amount}, else: {:error, :non_negative}
  end

  def get_transactions(%BankAccount{} = bank_account, nil) do
    get_transactions(bank_account, DateTime.add(DateTime.utc_now(), -1, :day))
  end

  def get_transactions(
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
         {:ok, transactions} <- TrueLayer.get_card_transactions(bank_connection, bank_account.external_account_id, since)
    do
      {:ok, transactions}
    end
  end

  def renew_connection(%BankConnection{} = bank_connection) do
    with {:ok, renewed_token} <- TrueLayer.renew_token(bank_connection.refresh_token),
         {:ok, renewed_connection} <- Plans.update_bank_connection(bank_connection, Map.from_struct(renewed_token))
    do
      {:ok, renewed_connection}
    end
  end

  defp sum_transactions(transactions) do
    Enum.reduce(transactions, Money.new(0), fn txn, acc -> Money.add(acc, txn.amount) end)
  end

  def transfer_funds(amount, mandate) do
    {:ok, %{id: _payment_id}} = TrueLayer.create_payment_on_mandate(mandate.external_id, amount)
    {:ok, amount}
  end
end
