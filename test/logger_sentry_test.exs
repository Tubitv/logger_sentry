defmodule LoggerSentryTest do
  use ExUnit.Case
  alias Logger.Backends.Sentry, as: LoggerSentry
  require Logger

  test "sentry backend level" do
    assert :ok == LoggerSentry.level(:info)
    assert :info == LoggerSentry.level()
    assert :debug == Logger.level()
    # set log level
    assert :ok == LoggerSentry.level(:error)
    assert :error_level == LoggerSentry.level(:fake_level)
    # get sentry log level
    assert :error == LoggerSentry.level()
    # get Logger level
    assert :debug == Logger.level()
    # set Logger level
    assert :ok == Logger.configure(level: :info)
    # get sentry log level
    assert :error == LoggerSentry.level()
  end

  test "sentry log" do
    assert :ok == LoggerSentry.level(:debug)
    Logger.info("info_message")
    assert :ok == wait_for_ets(10, {:info, "info_message"})
    Logger.error("error_message")
    assert :ok == wait_for_ets(10, {:error, "error_message"})

    assert :ok == LoggerSentry.level(:error)
    Logger.error("error_message")
    assert :ok == wait_for_ets(10, {:error, "error_message"})
    Logger.info("info_message")
    assert :ok == can_not_wait_for_ets(10)

    assert :ok == LoggerSentry.level(:warn)
    Logger.warn("warn_message")
    assert :ok == wait_for_ets(10, {:warn, "warn_message"})
  end

  test "sentry metadata" do
    assert [] == LoggerSentry.metadata()
    assert :error_metadata == LoggerSentry.metadata(:fake_meta)
    assert :error_metadata == LoggerSentry.metadata([:fake_meta])
    assert :ok == LoggerSentry.metadata(:all)
    Logger.error("error_message")
    assert :ok == LoggerSentry.metadata([:file, :line, :pid])
    Logger.error("error_message")
    assert :ok == LoggerSentry.metadata([])
    assert [] == LoggerSentry.metadata()
    assert :ets.delete_all_objects(:__just_prepare_for_logger_sentry__)
  end

  defp wait_for_ets(0, _), do: exit("wait_for_ets timeout")

  defp wait_for_ets(n, {level, message}) do
    case :ets.lookup(:__just_prepare_for_logger_sentry__, level) do
      [{_, ^message}] ->
        :ets.delete(:__just_prepare_for_logger_sentry__, level)
        :ok

      [] ->
        Process.sleep(500)
        wait_for_ets(n - 1, {level, message})
    end
  end

  defp can_not_wait_for_ets(0), do: :ok

  defp can_not_wait_for_ets(n) do
    case :ets.tab2list(:__just_prepare_for_logger_sentry__) do
      [] ->
        Process.sleep(200)
        can_not_wait_for_ets(n - 1)

      _ ->
        exit("should not has result in ets table")
    end
  end
end
