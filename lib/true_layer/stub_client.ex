defmodule TrueLayer.StubClient do
  alias TrueLayer.Transaction
  alias TrueLayer.AccessToken

  @behaviour TrueLayer

  def renew_token(refresh_token) do
    token = %AccessToken{
      access_token: "stub_access_token",
      expires_at: DateTime.add(DateTime.utc_now(), 1, :day),
      refresh_token: refresh_token}
    {:ok, token}
  end

  def get_card_transactions(_bank_connection, _account_id, _since) do
    transactions = [
      Transaction.new(%{"amount" => -100.0, "currency" => "GBP"}),
      Transaction.new(%{"amount" => -12.34, "currency" => "GBP"}),
      Transaction.new(%{"amount" => 50.0, "currency" => "GBP"}),
    ]
    {:ok, transactions}
  end
end
