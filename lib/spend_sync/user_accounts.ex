defmodule SpendSync.UserAccounts do
  @moduledoc """
  The UserAccounts context.
  """
  alias SpendSync.Repo
  alias SpendSync.UserAccounts.User

  def list_users() do
    Repo.all(User)
  end

  def get_user!(id) do
    Repo.get!(User, id)
  end
end
