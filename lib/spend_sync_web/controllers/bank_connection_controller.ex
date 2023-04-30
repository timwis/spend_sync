defmodule SpendSyncWeb.BankConnectionController do
  use SpendSyncWeb, :controller

  alias SpendSync.Plans
  alias SpendSync.Plans.BankConnection
  alias SpendSync.UserAccounts

  def index(conn, _params) do
    bank_connections = Plans.list_bank_connections()
    render(conn, :index, bank_connections: bank_connections)
  end

  def new(conn, _params) do
    changeset = Plans.change_bank_connection(%BankConnection{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"bank_connection" => bank_connection_params}) do
    user = UserAccounts.get_user!(bank_connection_params["user_id"])
    case Plans.create_bank_connection(user, bank_connection_params) do
      {:ok, bank_connection} ->
        conn
        |> put_flash(:info, "Bank connection created successfully.")
        |> redirect(to: ~p"/bank_connections/#{bank_connection}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    bank_connection = Plans.get_bank_connection!(id)
    render(conn, :show, bank_connection: bank_connection)
  end

  def edit(conn, %{"id" => id}) do
    bank_connection = Plans.get_bank_connection!(id)
    changeset = Plans.change_bank_connection(bank_connection)
    render(conn, :edit, bank_connection: bank_connection, changeset: changeset)
  end

  def update(conn, %{"id" => id, "bank_connection" => bank_connection_params}) do
    bank_connection = Plans.get_bank_connection!(id)

    case Plans.update_bank_connection(bank_connection, bank_connection_params) do
      {:ok, bank_connection} ->
        conn
        |> put_flash(:info, "Bank connection updated successfully.")
        |> redirect(to: ~p"/bank_connections/#{bank_connection}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, bank_connection: bank_connection, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    bank_connection = Plans.get_bank_connection!(id)
    {:ok, _bank_connection} = Plans.delete_bank_connection(bank_connection)

    conn
    |> put_flash(:info, "Bank connection deleted successfully.")
    |> redirect(to: ~p"/bank_connections")
  end
end
