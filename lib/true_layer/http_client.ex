defmodule TrueLayer.HttpClient do
  @behaviour TrueLayer
  @config Application.compile_env(:spend_sync, TrueLayer, [])

  alias Tesla.Env
  alias SpendSync.Plans.BankConnection
  alias TrueLayer.AccessToken
  alias TrueLayer.Transaction

  # def client(subdomain \\ "api", access_token \\ nil) do
  def client(opts \\ []) do
    test_env? = Application.get_env(:spend_sync, :env) == :test

    [
      {Tesla.Middleware.BaseUrl, get_base_url(opts)},
      {Tesla.Middleware.Headers, get_headers(opts)},
      Tesla.Middleware.JSON
    ]
    |> append_if(test_env?, Tesla.Middleware.KeepRequest)
    |> append_if(Keyword.has_key?(opts, :sign_request), TrueLayer.RequestSigning.Middleware)
    |> Tesla.client()
  end

  defp get_base_url(opts) do
    subdomain = Keyword.get(opts, :subdomain, "api")
    domain = "truelayer-sandbox.com"
    "https://#{subdomain}.#{domain}"
  end

  defp get_headers(opts) do
    headers = []

    access_token = Keyword.get(opts, :access_token)

    headers =
      if access_token, do: [{"Authorization", "Bearer #{access_token}"} | headers], else: headers

    idempotency_key = Keyword.get(opts, :idempotency_key)

    headers =
      if idempotency_key, do: [{"Idempotency-Key", idempotency_key} | headers], else: headers

    headers
  end

  def renew_token(refresh_token) do
    request_body =
      @config
      |> Keyword.take([:client_id, :client_secret])
      |> Keyword.put(:grant_type, "refresh_token")
      |> Keyword.put(:refresh_token, refresh_token)
      |> Map.new()

    with {:ok, response} <- Tesla.post(client(subdomain: "auth"), "/connect/token", request_body),
         %Env{status: 200, body: %{"expires_in" => _} = response_body} <- response do
      {:ok, AccessToken.new(response_body)}
    else
      %Env{status: 400, body: %{"error" => reason}} -> {:error, reason}
      {:error, _reason} = err -> err
    end
  end

  def get_card_transactions(%BankConnection{access_token: access_token}, account_id, since) do
    query = [from: DateTime.to_iso8601(since), to: DateTime.to_iso8601(DateTime.utc_now())]
    url = "/data/v1/cards/#{account_id}/transactions"

    # %Env{body: %{"results" => transactions}} = Tesla.get!(client("api", access_token), url, query: query)
    # case Tesla.get(client("api", access_token), url, query: query) do
    #   {:ok, %Env{status: 200} = response} ->
    #     {:ok, Enum.map(response.body["results"], &Transaction.new/1)}
    #   other -> other
    # end
    %Env{status: 200, body: response_body} =
      Tesla.get!(client(subdomain: "api", access_token: access_token), url, query: query)

    {:ok, Enum.map(response_body["results"], &Transaction.new/1)}
  end

  def create_payment_on_mandate(mandate_id, %Money{} = amount) do
    {:ok, access_token} = generate_client_credentials_token("payments")

    request_body = %{
      amount_in_minor: amount.amount,
      currency: amount.currency,
      payment_method: %{
        type: "method",
        mandate_id: mandate_id
      }
    }

    opts = [
      subdomain: "api",
      access_token: access_token.access_token,
      sign_request: true,
      idempotency_key: UUID.uuid4()
    ]

    with {:ok, response} <- Tesla.post(client(opts), "/payments", request_body),
         %Env{status: 200, body: response_body} = response do
      {:ok, response_body}
    end
  end

  defp generate_client_credentials_token(scope) do
    url = "/connect/token"

    request_body =
      @config
      |> Keyword.take([:client_id, :client_secret])
      |> Keyword.put(:grant_type, "client_credentials")
      |> Keyword.put(:scope, scope)
      |> Map.new()

    with {:ok, response} <- Tesla.post(client(subdomain: "auth"), url, request_body),
         %Env{status: 200, body: response_body} <- response do
      {:ok, AccessToken.new(response_body)}
    else
      %Env{status: 400..500, body: %{"error" => reason}} -> {:error, reason}
    end
  end

  defp append_if(list, condition, item) do
    if condition, do: list ++ [item], else: list
  end
end
