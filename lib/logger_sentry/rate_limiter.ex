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

  alias LoggerSentry.TaskSupervisor

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

  # Invalid options can be passed to Sentry.capture_message/2 which have caused
  # the GenServer to crash repeatedly and take down the supervision tree.
  # We use a separate task to avoid that and to maintain the current behavior
  # of the public API.
  def handle_cast({:send_rate_limited, output, options}, strategy) do
    case strategy.module.check(strategy) do
      {:ok, new_strategy} ->
        Task.Supervisor.async_nolink(TaskSupervisor, fn ->
          Sentry.capture_message(output, options)
        end)

        {:noreply, new_strategy}

      {:skip, new_strategy} ->
        {:noreply, new_strategy}
    end
  end

  # Ignore any messages produced from Task.Supervisor.async_nolink via Sentry.

  def handle_info({:DOWN, _ref, _type, _pid, _reason}, state) do
    {:noreply, state}
  end

  def handle_info({ref, _result}, state) when is_reference(ref) do
    {:noreply, state}
  end
end
