defmodule LoggerSentry.RateLimiter.TokenBucket do
  @moduledoc """
  An implementation of a token bucket rate-limiting strategy.
  Essentially, in some time period (ex. one minute), there are
  X number of tokens available. One request consumes one token.
  If no tokens, then no more requests may run. After the time 
  interval has elapsed, the token count is restored to max.
  """

  alias LoggerSentry.RateLimiter.Strategy

  @behaviour LoggerSentry.RateLimiter

  @enforce_keys [:next_refresh, :tokens, :max_tokens, :interval_ms, :time_now]
  defstruct [:next_refresh, :tokens, :max_tokens, :interval_ms, :time_now]

  @impl LoggerSentry.RateLimiter
  def init(opts) do
    max_tokens = Keyword.get(opts, :token_count, 60)
    interval_ms = Keyword.get(opts, :interval_ms, :timer.minutes(1))
    time_now = Keyword.get(opts, :time_now, &now/0)

    state = %__MODULE__{
      next_refresh: next_refresh_time_from_now(time_now.(), interval_ms),
      tokens: max_tokens,
      max_tokens: max_tokens,
      interval_ms: interval_ms,
      time_now: time_now
    }

    Strategy.new(__MODULE__, state)
  end

  @impl LoggerSentry.RateLimiter
  def check(strategy = %Strategy{state: state}) do
    {status, new_state} =
      cond do
        # Time interval elapsed, refill tokens and consume one.
        state.time_now.() >= state.next_refresh ->
          next_refresh = next_refresh_time_from_now(state)
          tokens = state.max_tokens - 1
          {:ok, %__MODULE__{state | next_refresh: next_refresh, tokens: tokens}}

        # Consume a token, if any present.
        state.tokens > 0 ->
          {:ok, %__MODULE__{state | tokens: state.tokens - 1}}

        # No more tokens, skip the request.
        true ->
          {:skip, state}
      end

    {status, %Strategy{strategy | state: new_state}}
  end

  defp now() do
    :erlang.monotonic_time(:millisecond)
  end

  defp next_refresh_time_from_now(%__MODULE__{interval_ms: interval_ms, time_now: time_now}) do
    next_refresh_time_from_now(time_now.(), interval_ms)
  end

  defp next_refresh_time_from_now(now, interval_ms) do
    now + interval_ms
  end
end
