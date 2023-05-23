defmodule TrueLayer.RequestSigning do
  @alg "ES512"
  @tl_version "2"

  defmodule Request do
    @enforce_keys [:method, :path, :headers, :body]
    defstruct [:method, :path, :body, headers: []]
  end

  def sign(%Request{} = request, opts \\ []) do
    config = get_config(opts)
    key_id = Keyword.fetch!(config, :key_id)
    private_key = Keyword.fetch!(config, :private_key)

    jws_header = build_jws_header(request, key_id)
    jws_payload = build_jws_payload(request)

    [jws_header_b64, _jws_payload_b64, jws_signature] =
      JOSE.JWK.from_pem(private_key)
      |> JOSE.JWS.sign(jws_payload, jws_header)
      |> JOSE.JWS.compact()
      |> elem(1)
      |> String.split(".", parts: 3)

    {:ok, "#{jws_header_b64}..#{jws_signature}"}
  end

  def verify(%Request{} = request, opts \\ []) do
    config = get_config(opts)
    public_key = Keyword.fetch!(config, :public_key)
    jwk = JOSE.JWK.from_pem(public_key)

    jws_payload_b64 =
      request
      |> delete_header("tl-signature")
      |> build_jws_payload()
      |> Base.encode64(padding: false)

    with {:ok, tl_signature} <- get_header(request, "tl-signature"),
         [jws_header_b64, jws_signature] <- String.split(tl_signature, "..", parts: 2),
         full_jws <- Enum.join([jws_header_b64, jws_payload_b64, jws_signature], "."),
         {true, _, _} <- JOSE.JWS.verify_strict(jwk, [@alg], full_jws) do
      :ok
    else
      {:error, :missing_header} ->
        {:error, :missing_signature}

      {false, _, _} ->
        {:error, :invalid_signature}

      [_tl_signature_without_separator] ->
        {:error, :invalid_signature}
    end
  end

  defp get_config(overrides \\ []) do
    Application.fetch_env!(:spend_sync, TrueLayer)
    |> Keyword.merge(overrides)
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
    method = prepare_method(request.method)
    path = prepare_path(request.path)

    header_pairs =
      request.headers
      |> Enum.map(fn {key, val} -> "#{key}: #{val}" end)
      |> Enum.join("\n")

    """
    #{method} #{path}
    #{header_pairs}
    #{request.body}
    """
    |> String.trim()
  end

  defp prepare_method(method) do
    method
    |> to_string()
    |> String.upcase()
  end

  defp prepare_path(path) do
    String.replace_trailing(path, "/", "")
  end

  defp get_header(%Request{headers: headers}, key) do
    case List.keyfind(headers, key, 0) do
      {_, value} -> {:ok, value}
      _ -> {:error, :missing_header}
    end
  end

  def delete_header(%Request{} = request, key) when is_binary(key) do
    headers = for {k, v} <- request.headers, k != key, do: {k, v}
    %{request | headers: headers}
  end
end
