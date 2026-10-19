defmodule ElixirLlm.AI.GeminiWorker do
  @moduledoc """
  Calls Gemini 2.5 Flash API with streaming support.
  Streams tokens back via a callback function.
  """

  require Logger

  @model "gemini-2.5-flash-preview-04-17"

  def stream_response(prompt, _session_id, callback) do
    api_key = Application.get_env(:elixir_llm, :gemini_api_key)
    url = "https://generativelanguage.googleapis.com/v1beta/models/#{@model}:streamGenerateContent?alt=sse&key=#{api_key}"

    body = Jason.encode!(%{
      contents: [%{parts: [%{text: prompt}]}]
    })

    full_response = stream_sse(url, body, callback)
    callback.({:done, full_response})
  rescue
    error ->
      Logger.error("Gemini API error: #{inspect(error)}")
      callback.({:error, "Failed to get AI response"})
  end

  defp stream_sse(url, body, callback) do
    ref = make_ref()

    _resp = Req.post!(url,
      body: body,
      headers: [{"content-type", "application/json"}],
      into: fn {:data, data}, {req, resp} ->
        chunks = parse_sse_data(data)
        for text <- chunks do
          send(self(), {ref, :chunk, text})
        end
        {:cont, {req, resp}}
      end,
      receive_timeout: 60_000
    )

    collect_chunks(ref, callback)
  end

  defp collect_chunks(ref, callback, acc \\ "") do
    receive do
      {^ref, :chunk, text} ->
        callback.({:chunk, text})
        collect_chunks(ref, callback, acc <> text)
    after
      0 -> acc
    end
  end

  defp parse_sse_data(data) do
    data
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "data: "))
    |> Enum.map(&String.trim_leading(&1, "data: "))
    |> Enum.reject(&(&1 == "[DONE]"))
    |> Enum.flat_map(fn json_str ->
      case Jason.decode(json_str) do
        {:ok, %{"candidates" => [%{"content" => %{"parts" => parts}} | _]}} ->
          Enum.map(parts, & &1["text"])

        _ ->
          []
      end
    end)
  end
end
