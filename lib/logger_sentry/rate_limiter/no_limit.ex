defmodule LoggerSentry.RateLimiter.NoLimit do
  alias LoggerSentry.RateLimiter.Strategy

  @behaviour LoggerSentry.RateLimiter

  @impl LoggerSentry.RateLimiter
  def init(_opts) do
    %Strategy{module: __MODULE__, state: nil}
  end

  @impl LoggerSentry.RateLimiter
  def check(strategy) do
    {:ok, strategy}
  end
end
