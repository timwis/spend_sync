defmodule TrueLayer.RequestSigningTest do
  use SpendSync.DataCase, async: true

  alias Tesla.Env
  alias TrueLayer.RequestSigning
  alias TrueLayer.RequestSigning.Request
  alias TrueLayer.RequestSigning.SigningMiddleware

  test "adds tl-signature header" do
    options = [key_id: "test_key", private_key: "test/support/test_keys/ec512-private.pem"]

    request = %Env{
      method: :post,
      url: "https://example.com/mandates",
      body: Jason.encode!(%{"foo" => "bar"}),
      headers: [{"Idempotency-Key", "123"}]
    }

    assert {:ok, env} = SigningMiddleware.call(request, [], options)
    tl_signature = Tesla.get_header(env, "tl-signature")
    assert tl_signature != nil
  end

  test "generated signature verifies" do
    options = [
      key_id: "test_key",
      private_key: "test/support/test_keys/ec512-private.pem",
      public_key: "test/support/test_keys/ec512-public.pem"
    ]

    request = %Request{
      method: :post,
      path: "/mandates",
      body: Jason.encode!(%{"foo" => "bar"}),
      headers: [{"Idempotency-Key", "123"}]
    }

    assert {:ok, tl_signature} = RequestSigning.sign(request, options)

    signed_request = put_header(request, "tl-signature", tl_signature)
    assert :ok = RequestSigning.verify(signed_request, options)
  end

  # test "verifier fails on invalid signature" do

  defp put_header(%Request{} = request, key, value) do
    headers = List.keystore(request.headers, key, 0, {key, value})
    %{request | headers: headers}
  end
end
