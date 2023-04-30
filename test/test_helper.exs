{:ok, _} = Application.ensure_all_started(:ex_machina)

Mox.defmock(MockTrueLayer, for: TrueLayer)
Mox.stub_with(MockTrueLayer, TrueLayer.StubClient)
Application.put_env(:spend_sync, :true_layer_client, MockTrueLayer)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(SpendSync.Repo, :manual)
