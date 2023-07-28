defmodule LoggerSentryTest do
  use ExUnit.Case

  alias LoggerSentry.Sentry
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
    Logger.warning("warn_message")
    assert :ok == wait_for_ets(10, {:warning, "warn_message"})
  end

  test "sentry log with skip_sentry" do
    assert :ok == LoggerSentry.level(:debug)

    for {f, msg} <- [
          {:debug, "debug_message"},
          {:info, "info_message"},
          {:warning, "warn_message"},
          {:error, "error_message"}
        ] do
      :erlang.apply(Logger, :bare_log, [f, msg, [logger_sentry: [skip_sentry: true]]])
      assert catch_exit(wait_for_ets(2, {f, msg})) == "wait_for_ets timeout"
    end
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

  test "generate sentry options empty" do
    assert [extra: %{log_message: "error info"}] == Sentry.generate_opts([], "error info")
  end

  test "generate sentry options extra from metadata extra" do
    assert [extra: %{version: "0.1.1", log_message: "error info"}] ==
             Sentry.generate_opts([extra: %{version: "0.1.1"}], "error info")
  end

  test "generate sentry options extra" do
    assert [
             extra: %{application: Application, log_message: "error info", module: ModA},
             application: Application,
             module: ModA
           ] == Sentry.generate_opts([application: Application, module: ModA], "error info")
  end

  test "generate sentry options with self fingerprint" do
    assert [{:fingerprint, ["self fingerprint"]}, {:extra, %{log_message: "error info"}}] ==
             Sentry.generate_opts([fingerprint: ["self fingerprint"]], "error info")
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
