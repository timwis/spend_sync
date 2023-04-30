defmodule SpendSync.Factory do
  use ExMachina.Ecto, repo: SpendSync.Repo

  alias SpendSync.UserAccounts.User
  alias SpendSync.Plans.{
    BankAccount,
    BankConnection,
    Plan
  }
  alias TrueLayer.Transaction

  def user_factory do
    %User{
      email: sequence(:email, &"email-#{&1}@example.com")
    }
  end

  def bank_connection_factory do
    one_day_from_now = DateTime.add(DateTime.utc_now(), 1, :day)
    %BankConnection{
      user: build(:user),
      provider: "true_layer",
      access_token: "test_access_token",
      refresh_token: "test_refresh_token",
      expires_at: one_day_from_now
    }
  end

  def bank_account_factory do
    %BankAccount{
      bank_connection: build(:bank_connection),
      account_type: "monitor",
      display_name: "Test account",
      external_account_id: "12345"
    }
  end

  def plan_factory do
    one_day_ago = DateTime.add(DateTime.utc_now(), -1, :day)
    %Plan{
      user: build(:user),
      last_synced_at: one_day_ago,
      monitor_account: build(:bank_account),
      source_account: build(:bank_account),
      destination_account: build(:bank_account),
    }
  end

  def transaction_factory do
    amount = :rand.uniform(2000) * 100.0
    Transaction.new(%{"amount" => amount, "currency" => "GBP"})
  end
end
