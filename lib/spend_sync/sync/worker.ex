defmodule SpendSync.Sync.Worker do
  use Oban.Worker, queue: :default

  alias SpendSync.Plans
  alias SpendSync.Sync

  @one_day 60 * 60 * 24

  @impl true
  def perform(%{args: %{"plan_id" => _plan_id} = args, attempt: 1}) do
    args
    |> new(schedule_in: @one_day)
    |> Oban.insert!()

    perform(%{args: args})
  end

  def perform(%{args: %{"plan_id" => plan_id}}) do
    plan = Plans.get_plan!(plan_id)
    Sync.perform_sync(plan)
  end
end
