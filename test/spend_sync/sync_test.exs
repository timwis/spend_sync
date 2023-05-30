defmodule SpendSync.SyncTest do
  use SpendSync.DataCase, async: true

  import Mox

  alias SpendSync.Sync
  alias SpendSync.Plans
  alias SpendSync.TransferLogs
  alias TrueLayer.StubClient
  alias TrueLayer.Transaction

  # TODO
  # - [ ] renews client credentials token when expired
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

    # TODO
    @tag :skip
    test "does not renew monitor_account token when not expired" do
      plan = insert(:plan)

      MockTrueLayer
      |> expect(:renew_token, 0, fn _ -> {:noop} end)

      Sync.perform_sync(plan)
      verify!()
    end

    test "passes last_synced_at to transaction query" do
      three_days_ago = DateTime.add(DateTime.utc_now(), -3, :day)
      plan = insert(:plan, last_synced_at: three_days_ago)

      MockTrueLayer
      |> expect(:get_card_transactions, fn bank_connection, account_id, since ->
        assert since == DateTime.truncate(three_days_ago, :second)
        StubClient.get_card_transactions(bank_connection, account_id, since)
      end)

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

    test "transfers sum of transactions" do
      plan = insert(:plan)

      transactions = [
        Transaction.new(%{"amount" => -100.0, "currency" => "GBP"}),
        Transaction.new(%{"amount" => -500.0, "currency" => "GBP"}),
        Transaction.new(%{"amount" => 50.0, "currency" => "GBP"})
      ]

      MockTrueLayer
      |> expect(:get_card_transactions, fn _bc, _acc, _since -> {:ok, transactions} end)
      |> expect(:create_payment_on_mandate, fn mandate_id, amount ->
        assert Money.equals?(amount, Money.parse!(550, :GBP))
        StubClient.create_payment_on_mandate(mandate_id, amount)
      end)

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

      {:ok, _transfer_log} = Sync.perform_sync(plan)
      transfer_logs = TransferLogs.list_transfer_logs()
      transfer_log = List.first(transfer_logs)

      assert length(transfer_logs) == 1
      assert Money.equals?(transfer_log.amount, Money.parse!(100, :GBP))
      assert length(transfer_log.metadata["transactions"]) == 1
      assert List.first(transfer_log.metadata["transactions"])["amount"]["amount"] == -10000
    end

    test "transfers specified percentage from plan" do
      plan = insert(:plan, percentage: 50)
      transactions = [Transaction.new(%{"amount" => -100.0, "currency" => "GBP"})]

      MockTrueLayer
      |> expect(:get_card_transactions, fn _bc, _acc, _since -> {:ok, transactions} end)
      |> expect(:create_payment_on_mandate, fn mandate_id, amount ->
        assert Money.equals?(amount, Money.parse!(50, :GBP))
        StubClient.create_payment_on_mandate(mandate_id, amount)
      end)

      Sync.perform_sync(plan)
    end

    test "updates last_synced_at if :ok" do
      one_day_ago = DateTime.add(DateTime.utc_now(), -1, :day)
      plan = insert(:plan, last_synced_at: one_day_ago)

      Sync.perform_sync(plan)
      plan = Plans.get_plan!(plan.id)

      assert DateTime.to_date(plan.last_synced_at) == Date.utc_today()
    end

    test "updates last_synced_at if :non_negative" do
      one_day_ago = DateTime.add(DateTime.utc_now(), -1, :day)
      plan = insert(:plan, last_synced_at: one_day_ago)
      transactions = [Transaction.new(%{"amount" => 100.0, "currency" => "GBP"})]

      MockTrueLayer
      |> expect(:get_card_transactions, fn _bc, _acc, _since -> {:ok, transactions} end)

      Sync.perform_sync(plan)
      plan = Plans.get_plan!(plan.id)

      assert DateTime.to_date(plan.last_synced_at) == Date.utc_today()
    end

    test "does not transfer funds when status is simulation" do
      plan = insert(:plan, status: :simulation)

      MockTrueLayer
      |> expect(:create_payment_on_mandate, 0, fn _, _ -> {:noop} end)

      Sync.perform_sync(plan)
      verify!()
    end

    test "creates transfer log when status is isimulation" do
      plan = insert(:plan, status: :simulation)

      Sync.perform_sync(plan)

      transfer_logs = TransferLogs.list_transfer_logs()
      assert length(transfer_logs) == 1

      transfer_log = hd(transfer_logs)
      assert transfer_log.status == "simulation"
    end

    @tag :skip
    test "creates transfer log when spend is non-negative" do
      plan = insert(:plan)
      transactions = [Transaction.new(%{"amount" => 100.0, "currency" => "GBP"})]

      MockTrueLayer
      |> expect(:get_card_transactions, fn _bc, _acc, _since -> {:ok, transactions} end)

      Sync.perform_sync(plan)

      transfer_logs = TransferLogs.list_transfer_logs()
      assert length(transfer_logs) == 1

      transfer_log = hd(transfer_logs)
      assert transfer_log.status == "simulation"
    end
  end
end
