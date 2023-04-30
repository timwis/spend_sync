defmodule SpendSync.Plans do
  @moduledoc """
  The Plans context.
  """

  import Ecto.Query, warn: false

  alias SpendSync.Repo
  alias SpendSync.Plans.Plan
  alias SpendSync.Plans.BankConnection
  alias SpendSync.UserAccounts.User

  @doc """
  Returns the list of plans.

  ## Examples

      iex> list_plans(one_day_ago)
      [%Plan{}, ...]

  """
  def list_plans(since) do
    query =
      from j in Plan,
        join: m in assoc(j, :monitor_account),
        join: s in assoc(j, :source_account),
        join: d in assoc(j, :destination_account),
        where: j.last_synced_at <= ^since,
        or_where: is_nil(j.last_synced_at),
        preload: [monitor_account: :bank_connection, source_account: :bank_connection, destination_account: :bank_connection]

    Repo.all(query)
  end

  @doc """
  Returns the list of bank_connections.

  ## Examples

      iex> list_bank_connections()
      [%BankConnection{}, ...]

  """
  def list_bank_connections do
    BankConnection
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Gets a single bank_connection.

  Raises if the Bank connection does not exist.

  ## Examples

      iex> get_bank_connection!(123)
      %BankConnection{}

  """
  def get_bank_connection!(id) do
    BankConnection
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a bank_connection.

  ## Examples

      iex> create_bank_connection(user, %{field: value})
      {:ok, %BankConnection{}}

      iex> create_bank_connection(user, %{field: bad_value})
      {:error, ...}

  """
  def create_bank_connection(%User{} = user, attrs \\ %{}) do
    %BankConnection{}
    |> change_bank_connection(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a bank_connection.

  ## Examples

      iex> update_bank_connection(bank_connection, %{field: new_value})
      {:ok, %BankConnection{}}

      iex> update_bank_connection(bank_connection, %{field: bad_value})
      {:error, ...}

  """
  def update_bank_connection(%BankConnection{} = bank_connection, attrs) do
    bank_connection
    |> BankConnection.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a BankConnection.

  ## Examples

      iex> delete_bank_connection(bank_connection)
      {:ok, %BankConnection{}}

      iex> delete_bank_connection(bank_connection)
      {:error, ...}

  """
  def delete_bank_connection(%BankConnection{} = _bank_connection) do
    raise "TODO"
  end

  @doc """
  Returns a data structure for tracking bank_connection changes.

  ## Examples

      iex> change_bank_connection(bank_connection)
      %Todo{...}

  """
  def change_bank_connection(%BankConnection{} = bank_connection, attrs \\ %{}) do
    bank_connection
    # |> Repo.preload(:user)
    |> BankConnection.changeset(attrs)
  end
end
