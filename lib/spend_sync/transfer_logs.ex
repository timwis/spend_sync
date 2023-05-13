defmodule SpendSync.TransferLogs do
  @moduledoc """
  The TransferLogs context.
  """

  import Ecto.Query, warn: false

  alias SpendSync.Repo
  alias SpendSync.Plans.Plan
  alias SpendSync.TransferLogs.TransferLog

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
