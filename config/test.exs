import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :spend_sync, SpendSync.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "spend_sync_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :spend_sync, SpendSyncWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "aHUY984yihs/2cNItJnfp1ryoT7cNfi1g6x5MHJfnLOo9Cj8/xinOcj+a1DasoaN",
  server: false

# In test we don't send emails.
config :spend_sync, SpendSync.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :debug # :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :tesla, adapter: Tesla.Mock

config :spend_sync, TrueLayer,
  domain: "truelayer-sandbox.com",
  client_id: "test_client_id",
  client_secret: "test_client_secret",
  key_id: "test_key_id",
  private_key: File.read!("test/support/test_keys/ec512-private.pem"),
  public_key: File.read!("test/support/test_keys/ec512-public.pem")

config :spend_sync, Oban, testing: :inline
