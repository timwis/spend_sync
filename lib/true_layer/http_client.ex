defmodule TrueLayer.HttpClient do
  @behaviour TrueLayer

  alias Tesla.Env
  alias SpendSync.Plans.BankConnection
  alias TrueLayer.AccessToken
  alias TrueLayer.Transaction
  alias TrueLayer.RequestSigning.SigningMiddleware

  def client(opts \\ []) do
    config = get_config(opts)
    should_sign? = Keyword.has_key?(config, :sign_request)

    [
      {Tesla.Middleware.BaseUrl, get_base_url(config)},
      {Tesla.Middleware.Headers, get_headers(config)},
      Tesla.Middleware.JSON
    ]
    |> append_if(should_sign?, SigningMiddleware)
    |> Tesla.client()
  end

  defp get_config(overrides \\ []) do
    Application.fetch_env!(:spend_sync, TrueLayer)
    |> Keyword.merge(overrides)
  end

  defp get_base_url(opts) do
    subdomain = Keyword.get(opts, :subdomain, "api")
    domain = Keyword.get(opts, :domain, "truelayer-sandbox.com")
    "https://#{subdomain}.#{domain}"
  end

  defp get_headers(opts) do
    access_token = Keyword.get(opts, :access_token)
    idempotency_key = Keyword.get(opts, :idempotency_key)

    []
    |> append_if(access_token, {"Authorization", "Bearer #{access_token}"})
    |> append_if(idempotency_key, {"idempotency-key", idempotency_key})
  end

  def renew_token(refresh_token) do
    request_body =
      get_config()
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
    opts = [subdomain: "api", access_token: access_token]

    with {:ok, response} <- Tesla.get(client(opts), url, query: query),
         %Env{status: 200, body: response_body} <- response,
         transactions = Enum.map(response_body["results"], &Transaction.new/1) do
      {:ok, transactions}
    end
  end

  def create_payment_on_mandate(mandate_id, %Money{} = amount) do
    {:ok, access_token} = generate_client_credentials_token("payments")

    request_body = %{
      amount_in_minor: amount.amount,
      currency: amount.currency,
      payment_method: %{
        type: "mandate",
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
         %Env{status: 201, body: %{"status" => "authorized"} = response_body} = response do
      {:ok, response_body}
    else
      %Env{status: 201, body: %{"status" => "failed"} = response_body} ->
        {:error, response_body}
    end
  end

  defp generate_client_credentials_token(scope) do
    url = "/connect/token"

    request_body =
      get_config()
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
