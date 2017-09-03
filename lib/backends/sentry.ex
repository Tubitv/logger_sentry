defmodule Logger.Backends.Sentry do

  @moduledoc """
  This module is the sentry backend for Logger and use LoggerBackends behaviour.
  It defines all callbacks of `LoggerBackends` behaviour:

    * init/1
    * log_event/2

  the function `init/1` will initital configure for the sentry backend, and
  function `log_event/2` will send the output to sentry server depends on
  the configure information of `sentry` application.

  """

  use LoggerBackends

  def init(_) do
    config = Application.get_env(:logger, :sentry, [])
    {:ok, init(config, %__MODULE__{})}
  end

if Mix.env() in [:test] do
  def log_event(output, %{level: level} = state) do
    case :ets.info(:__just_prepare_for_logger_sentry__) do
      :undefined ->
        :ignore
      _ ->
        :ets.insert(:__just_prepare_for_logger_sentry__, {level, output})
    end
    state
  end
else
  def log_event(output, state) do
    Sentry.capture_exception(output, [stacktrace: :erlang.get_stacktrace(),
                                      event_source: __MODULE__])
    state
  end
end

  defp init(config, state) do
    level = Keyword.get(config, :level, :info)
    format = Logger.Formatter.compile Keyword.get(config, :format)
    metadata = Keyword.get(config, :metadata, []) |> configure_metadata()
    %{state | format: format, metadata: metadata, level: level}
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

end
