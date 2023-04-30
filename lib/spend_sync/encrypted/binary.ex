defmodule SpendSync.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: SpendSync.Encrypted.Vault
end
