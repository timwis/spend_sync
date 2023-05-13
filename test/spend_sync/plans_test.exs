defmodule SpendSync.PlansTest do
  use SpendSync.DataCase, async: true

  import Tesla.Mock

  alias SpendSync.Plans
  alias SpendSync.Plans.BankConnection

  describe "plans" do
    test "list_plans/1 returns plans" do
      insert(:plan, %{})
      now = DateTime.utc_now()
      one_day_ago = DateTime.add(now, -1, :day)
      plans = Plans.list_plans(one_day_ago)
      assert length(plans) == 1
    end

    test "update_plan/1 with invalid percentage returns error changeset" do
      plan = insert(:plan)

      assert {:error, %Ecto.Changeset{}} =
               Plans.update_plan(plan, %{
                 percentage: 150,
                 last_synced_at: ~U[2022-01-01 00:00:00Z]
               })

      assert {:error, %Ecto.Changeset{}} = Plans.update_plan(plan, %{percentage: 0})
      assert {:error, %Ecto.Changeset{}} = Plans.update_plan(plan, %{percentage: -50})
    end
  end

  describe "bank_connections" do
    @invalid_attrs %{access_token: nil, expires_at: nil, provider: nil, refresh_token: nil}

    test "list_bank_connections/0 returns all bank_connections" do
      bank_connection = insert(:bank_connection)
      assert Plans.list_bank_connections() == [bank_connection]
    end

    test "get_bank_connection!/1 returns the bank_connection with given id" do
      bank_connection = insert(:bank_connection)
      assert Plans.get_bank_connection!(bank_connection.id) == bank_connection
    end

    test "create_bank_connection/2 with valid data creates a bank_connection" do
      valid_attrs = %{
        access_token: "some access_token",
        expires_at: ~U[2023-04-01 15:51:00Z],
        provider: "some provider",
        refresh_token: "some refresh_token"
      }

      user = insert(:user)

      assert {:ok, %BankConnection{} = bank_connection} =
               Plans.create_bank_connection(user, valid_attrs)

      assert bank_connection.access_token == "some access_token"
      assert bank_connection.expires_at == ~U[2023-04-01 15:51:00Z]
      assert bank_connection.provider == "some provider"
      assert bank_connection.refresh_token == "some refresh_token"
    end

    test "create_bank_connection/2 with invalid data returns error changeset" do
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Plans.create_bank_connection(user, @invalid_attrs)
    end

    test "update_bank_connection/2 with valid data updates the bank_connection" do
      bank_connection = insert(:bank_connection)

      update_attrs = %{
        access_token: "some updated access_token",
        expires_at: ~U[2023-04-02 15:51:00Z],
        provider: "some updated provider",
        refresh_token: "some updated refresh_token"
      }

      assert {:ok, %BankConnection{} = bank_connection} =
               Plans.update_bank_connection(bank_connection, update_attrs)

      assert bank_connection.access_token == "some updated access_token"
      assert bank_connection.expires_at == ~U[2023-04-02 15:51:00Z]
      assert bank_connection.provider == "some updated provider"
      assert bank_connection.refresh_token == "some updated refresh_token"
    end

    test "update_bank_connection/2 with invalid data returns error changeset" do
      bank_connection = insert(:bank_connection)

      assert {:error, %Ecto.Changeset{}} =
               Plans.update_bank_connection(bank_connection, @invalid_attrs)

      assert bank_connection == Plans.get_bank_connection!(bank_connection.id)
    end

    # TODO
    @tag :skip
    test "delete_bank_connection/1 deletes the bank_connection" do
      bank_connection = insert(:bank_connection)
      assert {:ok, %BankConnection{}} = Plans.delete_bank_connection(bank_connection)
      assert_raise Ecto.NoResultsError, fn -> Plans.get_bank_connection!(bank_connection.id) end
    end

    test "change_bank_connection/1 returns a bank_connection changeset" do
      bank_connection = insert(:bank_connection)
      assert %Ecto.Changeset{} = Plans.change_bank_connection(bank_connection)
    end
  end
end
