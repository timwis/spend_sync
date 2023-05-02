defmodule TrueLayer.RequestSigning do
  @alg "ES512"
  @tl_version "2"
  @config Application.compile_env(:spend_sync, :true_layer, [])

  defmodule Request do
    defstruct [:method, :path, :body, headers: []]
    @enforce_keys [:method, :path, :headers, :body]
  end

  def sign(%Request{} = request, opts \\ []) do
    config = Keyword.merge(@config, opts)
    key_id = Keyword.fetch!(config, :key_id)
    private_key = Keyword.fetch!(config, :private_key)

    jws_header = build_jws_header(request, key_id)
    jws_payload = build_jws_payload(request)

    [jws_header_b64, _jws_payload_b64, jws_signature] =
      JOSE.JWK.from_pem_file(private_key)
      |> JOSE.JWS.sign(jws_payload, jws_header)
      |> JOSE.JWS.compact()
      |> elem(1)
      |> String.split(".", parts: 3)

    {:ok, "#{jws_header_b64}..#{jws_signature}"}
  end

  def verify(%Request{} = request, opts \\ []) do
    config = Keyword.merge(@config, opts)
    public_key = Keyword.fetch!(config, :public_key)

    jws_payload_b64 =
      request
      |> delete_header("Tl-Signature")
      |> build_jws_payload()
      |> Base.encode64(padding: false)

    tl_signature = get_header(request, "Tl-Signature")
    [jws_header_b64, jws_signature] = String.split(tl_signature, "..", parts: 2)

    full_jws = Enum.join([jws_header_b64, jws_payload_b64, jws_signature], ".")

    JOSE.JWK.from_pem_file(public_key)
    |> JOSE.JWS.verify_strict([@alg], full_jws)
  end

  defp build_jws_header(%Request{} = request, key_id) do
    header_keys =
      request.headers
      |> Enum.map(fn {key, _val} -> key end)
      |> Enum.join(",")

    %{
      "alg" => @alg,
      "kid" => key_id,
      "tl_version" => @tl_version,
      "tl_headers" => header_keys
    }
  end

  defp build_jws_payload(%Request{} = request) do
    method = String.upcase(request.method)
    path = String.replace_trailing(request.path, "/", "")

    header_pairs =
      request.headers
      |> Enum.map(fn {key, val} -> "#{key}: #{val}" end)
      |> Enum.join("\n")

    """
    #{method} #{path}
    #{header_pairs}
    #{request.body}
    """ |> String.trim()
  end

  defp get_header(%Request{headers: headers}, key) do
    case List.keyfind(headers, key, 0) do
      {_, value} -> value
      _ -> nil
    end
  end

  def delete_header(%Request{} = request, key) when is_binary(key) do
    headers = for {k, v} <- request.headers, k != key, do: {k, v}
    %{request | headers: headers}
  end
end
