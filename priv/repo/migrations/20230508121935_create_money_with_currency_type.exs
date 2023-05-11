defmodule SpendSync.Repo.Migrations.CreateMoneyWithCurrencyType do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE public.money_with_currency AS (amount integer, currency varchar(3))
    """
  end

  def down do
    execute """
    DROP TYPE IF EXISTS public.money_with_currency
    """
  end
end
