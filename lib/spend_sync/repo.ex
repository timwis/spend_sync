defmodule SpendSync.Repo do
  use Ecto.Repo,
    otp_app: :spend_sync,
    adapter: Ecto.Adapters.Postgres
end
