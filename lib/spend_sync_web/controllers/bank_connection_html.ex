defmodule SpendSyncWeb.BankConnectionHTML do
  use SpendSyncWeb, :html

  import Phoenix.HTML.Form

  alias SpendSync.UserAccounts

  embed_templates "bank_connection_html/*"

  @doc """
  Renders a bank_connection form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def bank_connection_form(assigns)

  def user_select(f, changeset) do
    selected_user_id = Ecto.Changeset.get_change(changeset, :user_id)

    user_opts =
      for user <- UserAccounts.list_users(),
          do: [key: user.email, value: user.id, selected: user.id == selected_user_id]

    select(f, :user_id, user_opts)
  end
end
