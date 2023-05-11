defmodule SpendSync.SyncTest do
  use SpendSync.DataCase, async: true

  import Mox

  alias SpendSync.Sync
  alias TrueLayer.StubClient
  alias TrueLayer.Transaction

  # TODO
  # - [x] renews monitor_account token when expired
  # - [x] does not renew monitor_account token when not expired
  # - [ ] limits transaction query to last_synced_at
  # - [x] does not transfer when spend is not negative
  # - [x] transfers absolute value of spend
  # - [ ] renews client credentials token when expired
  # - [ ] updates last_synced_at if :ok or :noop
  # - [x] creates transfer log record
  # - [ ] supports multiple currencies in transactions

  setup do
    Mox.stub_with(MockTrueLayer, TrueLayer.StubClient)
    :ok
  end

  describe "perform_sync/1" do
    test "renews monitor_account token when expired" do
      one_day_ago = DateTime.add(DateTime.utc_now(), -1, :day)
      monitor_connection = insert(:bank_connection, expires_at: one_day_ago)
      monitor_account = insert(:bank_account, bank_connection: monitor_connection)
      plan = insert(:plan, monitor_account: monitor_account)

      MockTrueLayer
      |> expect(:renew_token, fn token -> StubClient.renew_token(token) end)

      Sync.perform_sync(plan)
      verify!()
    end

    @tag :skip # TODO
    test "does not renew monitor_account token when not expired" do
      plan = insert(:plan)

      MockTrueLayer
      |> expect(:renew_token, 0, fn _ -> {:noop} end)

      Sync.perform_sync(plan)
      verify!()
    end

    test "does not transfer when spend is not negative" do
      plan = insert(:plan)
      transactions = [Transaction.new(%{"amount" => 100.0, "currency" => "GBP"})]

      MockTrueLayer
      |> expect(:get_card_transactions, fn _bc, _acc, _since -> {:ok, transactions} end)
      |> expect(:create_payment_on_mandate, 0, fn _, _ -> {:noop} end)

      Sync.perform_sync(plan)
      verify!()
    end

    test "transfers absolute value of spend" do
      plan = insert(:plan)
      transactions = [Transaction.new(%{"amount" => -100.0, "currency" => "GBP"})]

      MockTrueLayer
      |> expect(:get_card_transactions, fn _bc, _acc, _since -> {:ok, transactions} end)
      |> expect(:create_payment_on_mandate, fn mandate_id, amount ->
        assert Money.equals?(amount, Money.parse!(100, :GBP))
        StubClient.create_payment_on_mandate(mandate_id, amount)
      end)

      Sync.perform_sync(plan)
      verify!()
    end

    test "creates transfer log" do
      plan = insert(:plan)
      transactions = [Transaction.new(%{"amount" => -100.0, "currency" => "GBP"})]

      MockTrueLayer
      |> expect(:get_card_transactions, fn _bc, _acc, _since -> {:ok, transactions} end)

      Sync.perform_sync(plan)
      transfer_logs = Sync.list_transfer_logs

      assert length(transfer_logs) == 1
      assert Money.equals?(List.first(transfer_logs).amount, Money.parse!(100, :GBP))
    end
  end

  describe "transfer_logs" do
    alias SpendSync.Sync.TransferLog

    @invalid_attrs %{amount: nil, external_id: nil, status: nil}

    test "list_transfer_logs/0 returns all transfer_logs" do
      transfer_log = insert(:transfer_log) |> Ecto.reset_fields([:plan])
      assert Sync.list_transfer_logs() == [transfer_log]
    end

  test "get_transfer_log!/1 returns the transfer_log with given id" do
    transfer_log = insert(:transfer_log) |> Ecto.reset_fields([:plan])
    assert Sync.get_transfer_log!(transfer_log.id) == transfer_log
  end

    test "create_transfer_log/2 with valid data creates a transfer_log" do
      plan = insert(:plan) |> Ecto.reset_fields([:source_account, :mandate])
      valid_attrs = %{amount: Money.new(4200), external_id: "7488a646-e31f-11e4-aace-600308960662", status: "some status"}

      assert {:ok, %TransferLog{} = transfer_log} = Sync.create_transfer_log(plan, valid_attrs)
      assert transfer_log.amount.amount == 4200
      assert transfer_log.external_id == "7488a646-e31f-11e4-aace-600308960662"
      assert transfer_log.status == "some status"
    end

    test "create_transfer_log/2 with invalid data returns error changeset" do
      plan = insert(:plan)
      assert {:error, %Ecto.Changeset{}} = Sync.create_transfer_log(plan, @invalid_attrs)
    end

    test "update_transfer_log/2 with valid data updates the transfer_log" do
      transfer_log = insert(:transfer_log)
      update_attrs = %{amount: Money.new(5300), external_id: "7488a646-e31f-11e4-aace-600308960668", status: "some updated status"}

      assert {:ok, %TransferLog{} = transfer_log} = Sync.update_transfer_log(transfer_log, update_attrs)
      assert Money.equals?(transfer_log.amount, Money.new(5300))
      assert transfer_log.external_id == "7488a646-e31f-11e4-aace-600308960668"
      assert transfer_log.status == "some updated status"
    end

    test "update_transfer_log/2 with invalid data returns error changeset" do
      transfer_log = insert(:transfer_log) |> Ecto.reset_fields([:plan])
      assert {:error, %Ecto.Changeset{}} = Sync.update_transfer_log(transfer_log, @invalid_attrs)
      assert transfer_log == Sync.get_transfer_log!(transfer_log.id)
    end

    test "delete_transfer_log/1 deletes the transfer_log" do
      transfer_log = insert(:transfer_log)
      assert {:ok, %TransferLog{}} = Sync.delete_transfer_log(transfer_log)
      assert_raise Ecto.NoResultsError, fn -> Sync.get_transfer_log!(transfer_log.id) end
    end

    test "change_transfer_log/1 returns a transfer_log changeset" do
      transfer_log = insert(:transfer_log)
      assert %Ecto.Changeset{} = Sync.change_transfer_log(transfer_log)
    end
  end
end
