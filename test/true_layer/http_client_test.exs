defmodule TrueLayer.HttpClientTest do
  use SpendSync.DataCase, async: true

  # alias Tesla.Env
  import Tesla.Mock
  import TrueLayer.HttpClient, only: [create_payment_on_mandate: 2]

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

            assert Tesla.get_header(env, "Idempotency-Key") != nil, "expected presence of Idempotency-Key header"
            assert Tesla.get_header(env, "Tl-Signature") != nil, "expected presence of Tl-Signature header"
            assert body["payment_method"]["mandate_id"] == mandate.external_id, "expected mandate_id to match mandate's external_id"

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
