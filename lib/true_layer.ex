defmodule TrueLayer do
  alias SpendSync.Plans.BankConnection
  alias TrueLayer.AccessToken
  alias TrueLayer.Transaction

  @callback renew_token(refresh_token :: String.t()) :: {:ok, renewed_token :: %AccessToken{}} | {:error, reason :: String.t()}
  def renew_token(refresh_token), do: impl().renew_token(refresh_token)

  @callback get_card_transactions(bank_connection :: %BankConnection{}, account_id :: String.t(), since :: DateTime.t()) :: {:ok, transactions :: list(%Transaction{})}
  def get_card_transactions(bank_connection, account_id, since), do: impl().get_card_transactions(bank_connection, account_id, since)

  defp impl, do: Application.get_env(:spend_sync, :true_layer_client, TrueLayer.HttpClient)
end
