defmodule LoggerSentry.RateLimiter.TokenBucket.Test do
  use ExUnit.Case

  alias LoggerSentry.RateLimiter.TokenBucket

  setup do
    {:ok, time_agent} = Agent.start_link(fn -> 0 end)
    time_now = fn -> Agent.get(time_agent, & &1) end
    step_time = fn -> Agent.update(time_agent, &(&1 + 1)) end
    token_bucket = TokenBucket.init(token_count: 3, interval_ms: 1, time_now: time_now)

    {:ok, token_bucket: token_bucket, step_time: step_time}
  end

  test "stop allowing requests when tokens are depeleted", %{token_bucket: token_bucket} do
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:skip, _} = TokenBucket.check(token_bucket)
  end

  test "tokens refill to max", %{token_bucket: token_bucket, step_time: step_time} do
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:skip, token_bucket} = TokenBucket.check(token_bucket)
    step_time.()
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:skip, _} = TokenBucket.check(token_bucket)
  end

  test "tokens partially refill to max", %{token_bucket: token_bucket, step_time: step_time} do
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    step_time.()
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:skip, _} = TokenBucket.check(token_bucket)
  end

  test "tokens don't go above max", %{token_bucket: token_bucket, step_time: step_time} do
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:skip, token_bucket} = TokenBucket.check(token_bucket)
    step_time.()
    step_time.()
    step_time.()
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:ok, token_bucket} = TokenBucket.check(token_bucket)
    assert {:skip, _} = TokenBucket.check(token_bucket)
  end
end
