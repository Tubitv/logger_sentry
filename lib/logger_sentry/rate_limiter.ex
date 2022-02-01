defmodule LoggerSentry.RateLimiter do
  @moduledoc """
  The top-level logic for rate limiting requests. Must be given a
  LoggerSentry.RateLimiter.Strategy to provide the details of the 
  actual rate-limiting algorithm. The algorithm is specified by the
  application config. The following example sets a rate limit of
  20 requests per minute using the token bucket algorithm.

  ```
  import Config

  config :logger_sentry, LoggerSentry.RateLimiter,
    rate_limiter_module: LoggerSentry.RateLimiter.TokenBucket,
    rate_limiter_options: [token_count: 20, interval_ms: 60_000]
  ```

  If no strategy is configured, then defaults to the strategy
  LoggerSentry.RateLimiter.NoLimit. As implied by the name, this 
  doesn't do any rate limiting.

  You may provide your own rate limiters as long as they conform to the 
  `LoggerSentry.RateLimiter` behaviour.
  """

  @type opts :: keyword()
  @type strategy :: __MODULE__.Strategy

  @callback init(opts()) :: strategy()
  @callback check(strategy()) :: {:ok | :skip, strategy()}

  use GenServer

  @name __MODULE__

  def start_link(opts) do
    name = Keyword.get(opts, :name, @name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def send_rate_limited(rate_limiter \\ @name, output, options) do
    GenServer.cast(rate_limiter, {:send_rate_limited, output, options})
  end

  ## GenServer callbacks

  def init(opts) do
    module = Keyword.get(opts, :rate_limiter_module) || __MODULE__.NoLimit
    options = Keyword.get(opts, :rate_limiter_options) || []
    strategy = module.init(options)

    {:ok, strategy}
  end

  def handle_cast({:send_rate_limited, output, options}, strategy) do
    case strategy.module.check(strategy) do
      {:ok, new_strategy} ->
        Sentry.capture_message(output, options)
        {:noreply, new_strategy}

      {:skip, new_strategy} ->
        {:noreply, new_strategy}
    end
  end
end
