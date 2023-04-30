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
  # - [ ] renews source/dest tokens when expired
  # - [ ] updates last_synced_at if :ok or :noop

  describe "perform_sync/1" do
    test "renews monitor_account token when expired" do
      one_day_ago = DateTime.add(DateTime.utc_now(), -1, :day)
      monitor_connection = insert(:bank_connection, expires_at: one_day_ago)
      monitor_account = insert(:bank_account, bank_connection: monitor_connection)
      plan = insert(:plan, monitor_account: monitor_account)

      expect(MockTrueLayer, :renew_token, fn token -> StubClient.renew_token(token) end)
      expect(MockTrueLayer, :get_card_transactions, fn a, b, c -> StubClient.get_card_transactions(a, b, c) end)
      Sync.perform_sync(plan)
      verify!()
    end

    @tag :skip # TODO
    test "does not renew monitor_account token when not expired" do
      plan = insert(:plan)
      expect(MockTrueLayer, :renew_token, 0, fn _ -> {:noop} end)
      expect(MockTrueLayer, :get_card_transactions, fn a, b, c -> StubClient.get_card_transactions(a, b, c) end)
      Sync.perform_sync(plan)
      verify!()
    end

    @tag :skip # TODO
    test "does not transfer when spend is not negative" do
      plan = insert(:plan)
      transactions = [Transaction.new(%{"amount" => 100.0, "currency" => "GBP"})]
      expect(MockTrueLayer, :get_card_transactions, fn _bc, _acc, _since -> transactions end)
      expect(MockTrueLayer, :transfer_funds, 0, fn _ -> {:noop} end)
      Sync.perform_sync(plan)
      verify!()
    end

    @tag :skip # TODO
    test "transfers absolute value of spend" do
      plan = insert(:plan)
      transactions = [Transaction.new(%{"amount" => -100.0, "currency" => "GBP"})]
      expect(MockTrueLayer, :get_card_transactions, fn _bc, _acc, _since -> transactions end)
      expect(MockTrueLayer, :transfer_funds, fn amount ->
        assert Money.equals?(amount, Money.parse(100, :GBP))
      end)
      Sync.perform_sync(plan)
      verify!()
    end
  end
end
