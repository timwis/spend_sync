defmodule TrueLayer.HttpClientTest do
  use SpendSync.DataCase, async: true

  # alias Tesla.Env
  import Tesla.Mock

  import TrueLayer.HttpClient

  describe "renew_token/1" do
    test "constructs payload" do
      mock(fn env ->
        case path(env.url) do
          "/connect/token" ->
            body = Jason.decode!(env.body)

            assert body["refresh_token"] == "1234"
            assert body["grant_type"] == "refresh_token"
            assert Map.has_key?(body, "client_id")
            assert Map.has_key?(body, "client_secret")

            {200, %{}, %{"access_token" => "test_access_token", "expires_in" => 1}}
        end
      end)

      renew_token("1234")
    end
  end

  describe "get_card_transactions/3" do
    test "constructs payload" do
      bank_connection = build(:bank_connection)
      three_days_ago = DateTime.add(DateTime.utc_now(), -3, :day)

      mock(fn env ->
        case path(env.url) do
          "/data/v1/cards/123/transactions" ->
            assert env.query[:from] == DateTime.to_iso8601(three_days_ago)

            {:ok, to_datetime, _} = DateTime.from_iso8601(env.query[:to])
            assert DateTime.to_date(to_datetime) == Date.utc_today()

            {200, %{}, %{"results" => []}}
        end
      end)

      get_card_transactions(bank_connection, "123", three_days_ago)
    end
  end

  describe "create_payment_on_mandate/2" do
    test "constructs payload" do
      mandate = build(:mandate)
      amount = Money.parse!("100.00", :GBP)

      mock(fn env ->
        case path(env.url) do
          "/connect/token" ->
            json(%{"access_token" => "test_access_token", "expires_in" => 3600})

          "/payments" ->
            body = Jason.decode!(env.body)

            assert Tesla.get_header(env, "idempotency-key") != nil,
                   "expected presence of idempotency-key header"

            assert Tesla.get_header(env, "tl-signature") != nil,
                   "expected presence of tl-signature header"

            assert body["payment_method"]["mandate_id"] == mandate.external_id,
                   "expected mandate_id to match mandate's external_id"

            {200, %{}, %{}}
        end
      end)

      create_payment_on_mandate(mandate.external_id, amount)
    end
  end

  defp path(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
  end
end
