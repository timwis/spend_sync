defmodule TrueLayer.Transaction do
  @derive {Jason.Encoder, only: [:amount, :timestamp]}
  defstruct amount: Money.new(0, "GBP"), timestamp: nil

  def new(%{"amount" => amount, "currency" => currency} = data) when is_float(amount) do
    struct(__MODULE__,
      amount: Money.parse!(amount, currency),
      timestamp: data["timestamp"]
    )
  end
end
