defmodule TrueLayer.RequestSigning.Middleware do
  alias TrueLayer.RequestSigning
  alias TrueLayer.RequestSigning.Request

  @behaviour Tesla.Middleware

  def call(%Tesla.Env{} = env, next, options) do
    path =
      env.url
      |> URI.parse()
      |> Map.get(:path)

    request = %Request{
      method: env.method,
      path: path,
      body: env.body,
      headers: env.headers
    }

    {:ok, tl_signature} = RequestSigning.sign(request, options)

    env
    |> Tesla.put_header("Tl-Signature", tl_signature)
    |> Tesla.run(next)
  end
end
