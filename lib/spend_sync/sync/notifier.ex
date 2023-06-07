defmodule SpendSync.Sync.Notifier do
  use Phoenix.Swoosh, template_root: "lib/spend_sync_email"
  alias SpendSync.Mailer

  def deliver_transfer_log_email(
        email_address,
        %{
          amount: _amount,
          status: _status,
          transactions: _transactions,
          raw_sum: _raw_sum,
          since: _since
        } = assigns
      ) do
    new()
    |> to(email_address)
    |> from({"Spend Sync", "spendsync@datadigest.app"})
    |> subject("Your daily spend sync")
    |> render_body("transfer_log_email.html", assigns)
    |> Mailer.deliver()
  end
end
