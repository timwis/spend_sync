defmodule TrueLayer.RequestSigning.SigningMiddleware do
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
    |> Tesla.put_header("tl-signature", tl_signature)
    |> Tesla.run(next)
  end
end
