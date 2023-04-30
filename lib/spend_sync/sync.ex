defmodule SpendSync.Sync do
  @moduledoc """
  The Sync context.
  """

  require Logger
  import Ecto.Query, warn: false

  alias SpendSync.Repo
  alias SpendSync.Plans
  alias SpendSync.Plans.Plan
  alias SpendSync.Plans.BankConnection
  alias SpendSync.Plans.BankAccount

  def perform_sync(%Plan{
        monitor_account: monitor_account,
        source_account: source_account,
        destination_account: destination_account,
        last_synced_at: last_synced_at
      } = plan) do
    with {:ok, transactions} <- get_transactions(monitor_account, last_synced_at),
         sum <- sum_transactions(transactions),
         {:ok, _sum} <- should_transfer?(sum),
         positive_sum <- Money.abs(sum),
         {:ok, sum_transferred} <- transfer_funds(positive_sum, source_account, destination_account)
    do
      {:ok, _plan} = update_plan(plan, %{last_synced_at: DateTime.utc_now()})
      {:ok, sum_transferred}
    else
      {:error, :non_negative} ->
        {:ok, _plan} = update_plan(plan, %{last_synced_at: DateTime.utc_now()})
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

  def transfer_funds(amount, _source_account, _destination_account) do
    {:ok, amount}
    # bank_connection =
    #   if AccessToken.expired?(source_account.bank_connection) do
    #     renew_connection!(source_account.bank_connection)
    #   else
    #     source_account.bank_connection
    #   end

    # Monzo.deposit_into_pot!(amount, bank_connection.access_token, source_account.external_account_id, destination_account.external_account_id)
  end

  alias SpendSync.Sync.BankConnection



  def update_plan(%Plan{} = plan, attrs \\ %{}) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end
end
