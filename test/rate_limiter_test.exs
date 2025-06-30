defmodule LoggerSentry.RateLimiter.Test do
  use ExUnit.Case, async: false
  use Mimic

  import ExUnit.CaptureLog

  alias LoggerSentry.RateLimiter
  alias LoggerSentry.RateLimiter.{NoLimit, TokenBucket}

  setup :set_mimic_global

  test "rate limiter defaults to no limit" do
    opts = [name: :NoLimit]
    {:ok, pid} = RateLimiter.start_link(opts)
    assert %{module: NoLimit} = :sys.get_state(pid)
  end

  test "create token bucket rate limiter with default options" do
    opts = [
      name: :DefaultOptions,
      rate_limiter_module: TokenBucket
    ]

    {:ok, pid} = RateLimiter.start_link(opts)

    assert %{module: TokenBucket, state: %{interval_ms: 60_000, max_tokens: 60}} =
             :sys.get_state(pid)
  end

  test "create token bucket rate limiter with custom options" do
    opts = [
      name: :CustomOptions,
      rate_limiter_module: TokenBucket,
      rate_limiter_options: [interval_ms: 1000, token_count: 20]
    ]

    {:ok, pid} = RateLimiter.start_link(opts)

    assert %{module: TokenBucket, state: %{interval_ms: 1000, max_tokens: 20}} =
             :sys.get_state(pid)
  end

  test "send unlimited by default" do
    me = self()
    stub(Sentry, :capture_message, fn msg, _ -> send(me, msg) end)

    tokens = 10

    for n <- 0..tokens do
      msg = "Msg #{n}"
      RateLimiter.send_rate_limited(msg, [])
      assert_receive ^msg
    end
  end

  test "send until tokens depleted" do
    me = self()
    stub(Sentry, :capture_message, fn msg, _ -> send(me, msg) end)

    tokens = 3

    opts = [
      name: :Depleted,
      rate_limiter_module: TokenBucket,
      rate_limiter_options: [token_count: tokens]
    ]

    assert {:ok, pid} = RateLimiter.start_link(opts)

    for n <- 0..tokens do
      msg = "Msg #{n}"
      RateLimiter.send_rate_limited(pid, msg, [])

      if n == tokens do
        refute_receive ^msg, 1000
      else
        assert_receive ^msg
      end
    end
  end

  test "does not crash rate limiter on unexpected options" do
    pid = start_supervised!({RateLimiter, name: Unexpected})
    opts = [unexpected: "option"]
    stub(Sentry, :capture_message, fn _, _ -> raise "error" end)

    assert "" =
             capture_log(fn ->
               assert :ok = RateLimiter.send_rate_limited(pid, "message", opts)
               Process.sleep(100)
             end)
  end
end
