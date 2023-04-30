defmodule TrueLayer.HttpClient do
  @behaviour TrueLayer

  alias SpendSync.Plans.BankConnection
  alias TrueLayer.AccessToken
  alias TrueLayer.Transaction

  def client(subdomain \\ "api", access_token \\ nil) do
    headers = if access_token, do: [{"Authorization", "Bearer #{access_token}"}], else: []
    test_env? = Application.get_env(:spend_sync, :env) == :test

    [
      {Tesla.Middleware.BaseUrl, "https://#{subdomain}.truelayer-sandbox.com"},
      {Tesla.Middleware.Headers, headers},
      Tesla.Middleware.JSON
    ]
    |> append_if(test_env?, Tesla.Middleware.KeepRequest)
    |> Tesla.client()
  end

  def renew_token(refresh_token) do
    request_body =
      config()
      |> Keyword.take([:client_id, :client_secret])
      |> Keyword.put(:grant_type, "refresh_token")
      |> Keyword.put(:refresh_token, refresh_token)
      |> Map.new()

    with {:ok, response} <- Tesla.post(client("auth"), "/connect/token", request_body),
      %Tesla.Env{status: 200, body: %{"expires_in" => _} = response_body} <- response
    do
      {:ok, AccessToken.new(response_body)}
    else
      %Tesla.Env{status: 400, body: %{"error" => reason}} -> {:error, reason}
      {:error, _reason} = err -> err
    end
  end

  def get_card_transactions(%BankConnection{access_token: access_token}, account_id, since) do
    query = [from: DateTime.to_iso8601(since), to: DateTime.to_iso8601(DateTime.utc_now())]
    url = "/data/v1/cards/#{account_id}/transactions"

    # %Tesla.Env{body: %{"results" => transactions}} = Tesla.get!(client("api", access_token), url, query: query)
    # case Tesla.get(client("api", access_token), url, query: query) do
    #   {:ok, %Tesla.Env{status: 200} = response} ->
    #     {:ok, Enum.map(response.body["results"], &Transaction.new/1)}
    #   other -> other
    # end
    %Tesla.Env{status: 200, body: response_body} =
      Tesla.get!(client("api", access_token), url, query: query)

    {:ok, Enum.map(response_body["results"], &Transaction.new/1)}
  end

  defp config do
    Application.fetch_env!(:spend_sync, TrueLayer)
  end

  defp append_if(list, condition, item) do
    if condition, do: list ++ [item], else: list
  end
end
