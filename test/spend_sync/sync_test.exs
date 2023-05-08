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
  # - [ ] creates transfer log record

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
  end
end
