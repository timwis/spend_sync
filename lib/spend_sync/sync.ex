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
  alias SpendSync.Sync.TransferLog

  def perform_sync(%Plan{} = plan) do
    with {:ok, transactions} <- get_transactions(plan.monitor_account, plan.last_synced_at),
         sum <- sum_transactions(transactions),
         :ok <- should_transfer?(sum),
         positive_sum <- Money.abs(sum),
         amount_to_transfer <- percent_of(positive_sum, plan.percentage),
         {:ok, %{"id" => payment_id}} <- transfer_funds(amount_to_transfer, plan.mandate) do
      {:ok, _plan} = Plans.update_plan(plan, %{last_synced_at: DateTime.utc_now()})

      create_transfer_log(plan, %{
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

  @doc """
  Returns the list of transfer_logs.

  ## Examples

      iex> list_transfer_logs()
      [%TransferLog{}, ...]

  """
  def list_transfer_logs do
    Repo.all(TransferLog)
  end

  @doc """
  Gets a single transfer_log.

  Raises `Ecto.NoResultsError` if the Transfer log does not exist.

  ## Examples

      iex> get_transfer_log!(123)
      %TransferLog{}

      iex> get_transfer_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transfer_log!(id), do: Repo.get!(TransferLog, id)

  @doc """
  Creates a transfer_log.

  ## Examples

      iex> create_transfer_log(plan, %{field: value})
      {:ok, %TransferLog{}}

      iex> create_transfer_log(plan, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transfer_log(%Plan{} = plan, attrs \\ %{}) do
    %TransferLog{}
    |> TransferLog.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:plan, plan)
    |> Repo.insert()
  end

  @doc """
  Updates a transfer_log.

  ## Examples

      iex> update_transfer_log(transfer_log, %{field: new_value})
      {:ok, %TransferLog{}}

      iex> update_transfer_log(transfer_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transfer_log(%TransferLog{} = transfer_log, attrs) do
    transfer_log
    |> TransferLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transfer_log.

  ## Examples

      iex> delete_transfer_log(transfer_log)
      {:ok, %TransferLog{}}

      iex> delete_transfer_log(transfer_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transfer_log(%TransferLog{} = transfer_log) do
    Repo.delete(transfer_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transfer_log changes.

  ## Examples

      iex> change_transfer_log(transfer_log)
      %Ecto.Changeset{data: %TransferLog{}}

  """
  def change_transfer_log(%TransferLog{} = transfer_log, attrs \\ %{}) do
    TransferLog.changeset(transfer_log, attrs)
  end
end
