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
  client_id: "test_client_id",
  client_secret: "test_client_secret",
  redirect_uri: "http://localhost:4000",
  key_id: "test_key_id",
  private_key:
    Base.decode64!(
      "LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1JSGNBZ0VCQkVJQk1KbVJmVS9uTXpPbkJuQTZ6WGdkZnBGNnVXZll2T0JDTTRsVW94RkRTRlM2bnFPMytYK1IKNDJHSjhPekt6THI5K0lxMjM4Q0wrMkJ4dzE0ZjNqcWlUdENnQndZRks0RUVBQ09oZ1lrRGdZWUFCQUNndTViaQpjV3FoUzVIeDNzVld4U2dqcmFXSnRoMUNWWWEwdEsyZXAyNTB0ajNadERTdHJsNWtCdVM2ZXNaTkgzN0QyYXZpCmpZUzNKdnFrTHRnSGI3YmRZd0Y5WEk1QmpJcGJZcEQ2NUYrUGFzTGlRM1hCRTJrN0kvcE1oVC9JN0JmVnVWd0EKZDJlTFFZa0xYTzlnMEp5V0hpc2dGZjArcW1VN1JTaGEvazZlSXJ2byt3PT0KLS0tLS1FTkQgRUMgUFJJVkFURSBLRVktLS0tLQo="
    ),
  public_key:
    Base.decode64!(
      "LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlHYk1CQUdCeXFHU000OUFnRUdCU3VCQkFBakE0R0dBQVFBb0x1VzRuRnFvVXVSOGQ3RlZzVW9JNjJsaWJZZApRbFdHdExTdG5xZHVkTFk5MmJRMHJhNWVaQWJrdW5yR1RSOSt3OW1yNG8yRXR5YjZwQzdZQjIrMjNXTUJmVnlPClFZeUtXMktRK3VSZmoyckM0a04xd1JOcE95UDZUSVUveU93WDFibGNBSGRuaTBHSkMxenZZTkNjbGg0cklCWDkKUHFwbE8wVW9XdjVPbmlLNzZQcz0KLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg=="
    )
