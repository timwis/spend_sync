defmodule SpendSync.TransferLogsTest do
  use SpendSync.DataCase, async: true

  alias SpendSync.TransferLogs
  alias SpendSync.TransferLogs.TransferLog

  describe "transfer_logs" do
    @invalid_attrs %{amount: nil, external_id: nil, status: nil}

    test "list_transfer_logs/0 returns all transfer_logs" do
      transfer_log = insert(:transfer_log) |> Ecto.reset_fields([:plan])
      assert TransferLogs.list_transfer_logs() == [transfer_log]
    end

    test "get_transfer_log!/1 returns the transfer_log with given id" do
      transfer_log = insert(:transfer_log) |> Ecto.reset_fields([:plan])
      assert TransferLogs.get_transfer_log!(transfer_log.id) == transfer_log
    end

    test "create_transfer_log/2 with valid data creates a transfer_log" do
      plan = insert(:plan) |> Ecto.reset_fields([:source_account, :mandate])

      valid_attrs = %{
        amount: Money.new(4200),
        external_id: "7488a646-e31f-11e4-aace-600308960662",
        status: "some status"
      }

      assert {:ok, %TransferLog{} = transfer_log} =
               TransferLogs.create_transfer_log(plan, valid_attrs)

      assert transfer_log.amount.amount == 4200
      assert transfer_log.external_id == "7488a646-e31f-11e4-aace-600308960662"
      assert transfer_log.status == "some status"
    end

    test "create_transfer_log/2 with invalid data returns error changeset" do
      plan = insert(:plan)
      assert {:error, %Ecto.Changeset{}} = TransferLogs.create_transfer_log(plan, @invalid_attrs)
    end

    test "update_transfer_log/2 with valid data updates the transfer_log" do
      transfer_log = insert(:transfer_log)

      update_attrs = %{
        amount: Money.new(5300),
        external_id: "7488a646-e31f-11e4-aace-600308960668",
        status: "some updated status"
      }

      assert {:ok, %TransferLog{} = transfer_log} =
               TransferLogs.update_transfer_log(transfer_log, update_attrs)

      assert Money.equals?(transfer_log.amount, Money.new(5300))
      assert transfer_log.external_id == "7488a646-e31f-11e4-aace-600308960668"
      assert transfer_log.status == "some updated status"
    end

    test "update_transfer_log/2 with invalid data returns error changeset" do
      transfer_log = insert(:transfer_log) |> Ecto.reset_fields([:plan])

      assert {:error, %Ecto.Changeset{}} =
               TransferLogs.update_transfer_log(transfer_log, @invalid_attrs)

      assert transfer_log == TransferLogs.get_transfer_log!(transfer_log.id)
    end

    test "delete_transfer_log/1 deletes the transfer_log" do
      transfer_log = insert(:transfer_log)
      assert {:ok, %TransferLog{}} = TransferLogs.delete_transfer_log(transfer_log)
      assert_raise Ecto.NoResultsError, fn -> TransferLogs.get_transfer_log!(transfer_log.id) end
    end

    test "change_transfer_log/1 returns a transfer_log changeset" do
      transfer_log = insert(:transfer_log)
      assert %Ecto.Changeset{} = TransferLogs.change_transfer_log(transfer_log)
    end
  end
end
