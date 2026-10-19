defmodule ElixirLlm.AI.RateLimiter do
  @moduledoc """
  Redis-based sliding window rate limiter.
  Limits requests per user within a time window.
  """

  @max_requests 20
  @window_seconds 60

  def check_rate(user_id) do
    key = "rate:#{user_id}"
    now = System.system_time(:second)
    window_start = now - @window_seconds

    # Redis pipeline: remove old entries, add current, count, set expiry
    commands = [
      ["ZREMRANGEBYSCORE", key, "0", to_string(window_start)],
      ["ZADD", key, to_string(now), "#{now}:#{:erlang.unique_integer()}"],
      ["ZCARD", key],
      ["EXPIRE", key, to_string(@window_seconds)]
    ]

    case Redix.pipeline(:redix, commands) do
      {:ok, [_removed, _added, count, _expire]} when count <= @max_requests ->
        :ok

      {:ok, _} ->
        {:error, :rate_limited}

      {:error, reason} ->
        # If Redis is down, allow the request (fail open for MVP)
        require Logger
        Logger.warning("Rate limiter Redis error: #{inspect(reason)}")
        :ok
    end
  end
end
