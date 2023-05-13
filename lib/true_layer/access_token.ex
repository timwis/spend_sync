defmodule TrueLayer.AccessToken do
  alias SpendSync.Plans.BankConnection

  defstruct [
    :access_token,
    :refresh_token,
    :expires_at
  ]

  def new(%{"expires_in" => expires_in} = data) do
    data
    |> Map.put_new("expires_at", get_expires_at(expires_in))
    |> Map.delete("expires_in")
    |> new()
  end

  def new(%{"expires_at" => expires_at} = data) do
    struct(__MODULE__,
      access_token: Map.get(data, "access_token"),
      refresh_token: Map.get(data, "refresh_token"),
      expires_at: expires_at
    )
  end

  def new(%__MODULE__{} = bank_connection) do
    struct(__MODULE__, Map.from_struct(bank_connection))
  end

  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) != :gt
  end

  def expired?(%BankConnection{} = bank_connection) do
    bank_connection
    |> new()
    |> expired?()
  end

  defp get_expires_at(expires_in) do
    DateTime.add(DateTime.utc_now(), expires_in, :second)
  end
end
