defmodule SpendSync.Plans do
  @moduledoc """
  The Plans context.
  """

  import Ecto.Query, warn: false

  alias SpendSync.Repo
  alias SpendSync.Plans.Plan
  alias SpendSync.Plans.BankConnection
  alias SpendSync.Plans.BankAccount
  alias SpendSync.Plans.Mandate
  alias SpendSync.UserAccounts.User

  @doc """
  Returns the list of plans.

  ## Examples

      iex> list_plans(one_day_ago)
      [%Plan{}, ...]

  """
  def list_plans(since) do
    query =
      from plan in Plan,
        join: monitor in assoc(plan, :monitor_account),
        join: mandate in assoc(plan, :mandate),
        where: plan.last_synced_at <= ^since,
        or_where: is_nil(plan.last_synced_at),
        preload: [:mandate, monitor_account: :bank_connection]

    Repo.all(query)
  end

  @doc """
  Gets a single plan.

  Raises if the plan does not exist.

  ## Examples

      iex> get_plan!(123)
      %Plan{}

  """
  def get_plan!(id) do
    Plan
    |> Repo.get!(id)
    |> Repo.preload([:user, :mandate, monitor_account: :bank_connection])
  end

  @doc """
  Creates a plan.

  ## Examples

      iex> create_plan(user, monitor_account, mandate, %{field: value})
      {:ok, %Plan{}}

      iex> create_plan(user, monitor_account, mandate, %{field: bad_value})
      {:error, ...}

  """
  def create_plan(
        %User{} = user,
        %BankAccount{} = monitor_account,
        %Mandate{} = mandate,
        attrs \\ %{}
      ) do
    %Plan{}
    |> change_plan(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:monitor_account, monitor_account)
    |> Ecto.Changeset.put_assoc(:mandate, mandate)
    |> Repo.insert()
  end

  @doc """
  Updates a plan.

  ## Examples

      iex> update_plan(plan, %{field: new_value})
      {:ok, %Plan{}}

      iex> update_plan(plan, %{field: bad_value})
      {:error, ...}

  """
  def update_plan(%Plan{} = plan, attrs \\ %{}) do
    plan
    |> change_plan(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a data structure for tracking plan changes.

  ## Examples

      iex> change_plan(plan)
      %Todo{...}

  """
  def change_plan(%Plan{} = plan, attrs \\ %{}) do
    plan
    # |> Repo.preload(:user)
    |> Plan.changeset(attrs)
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

  @doc """
  Returns the list of bank_accounts.

  ## Examples

      iex> list_bank_accounts()
      [%BankAccount{}, ...]

  """
  def list_bank_accounts do
    BankAccount
    |> preload(:bank_connection)
    |> Repo.all()
  end

  @doc """
  Gets a single bank_account.

  Raises if the Bank account does not exist.

  ## Examples

      iex> get_bank_account!(123)
      %BankAccount{}

  """
  def get_bank_account!(id) do
    BankAccount
    |> Repo.get!(id)
    |> Repo.preload(:bank_connection)
  end

  @doc """
  Creates a bank_account.

  ## Examples

      iex> create_bank_account(bank_connection, %{field: value})
      {:ok, %BankAccount{}}

      iex> create_bank_account(bank_connection, %{field: bad_value})
      {:error, ...}

  """
  def create_bank_account(%BankConnection{} = bank_connection, attrs \\ %{}) do
    %BankAccount{}
    |> change_bank_account(attrs)
    |> Ecto.Changeset.put_assoc(:bank_connection, bank_connection)
    |> Repo.insert()
  end

  @doc """
  Updates a bank_account.

  ## Examples

      iex> update_bank_account(bank_account, %{field: new_value})
      {:ok, %BankAccount{}}

      iex> update_bank_account(bank_account, %{field: bad_value})
      {:error, ...}

  """
  def update_bank_account(%BankAccount{} = bank_account, attrs) do
    bank_account
    |> BankAccount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a BankAccount.

  ## Examples

      iex> delete_bank_account(bank_account)
      {:ok, %BankConnection{}}

      iex> delete_bank_account(bank_account)
      {:error, ...}

  """
  def delete_bank_account(%BankAccount{} = _bank_account) do
    raise "TODO"
  end

  @doc """
  Returns a data structure for tracking bank_account changes.

  ## Examples

      iex> change_bank_account(bank_account)
      %Todo{...}

  """
  def change_bank_account(%BankAccount{} = bank_account, attrs \\ %{}) do
    bank_account
    |> BankAccount.changeset(attrs)
  end

  @doc """
  Gets a single mandate.

  Raises if the Mandate account does not exist.

  ## Examples

      iex> get_mandate!(123)
      %Mandate{}

  """
  def get_mandate!(id) do
    Mandate
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a mandate.

  ## Examples

      iex> create_mandate(user, %{field: value})
      {:ok, %Mandate{}}

      iex> create_mandate(user, %{field: bad_value})
      {:error, ...}

  """
  def create_mandate(%User{} = user, attrs \\ %{}) do
    %Mandate{}
    |> change_mandate(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Returns a data structure for tracking mandate changes.

  ## Examples

      iex> change_mandate(mandate)
      %Todo{...}

  """
  def change_mandate(%Mandate{} = mandate, attrs \\ %{}) do
    mandate
    # |> Repo.preload(:user)
    |> Mandate.changeset(attrs)
  end
end
