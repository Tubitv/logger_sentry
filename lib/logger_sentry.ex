defmodule Logger.Backends.Sentry do
  @moduledoc """
  This module is the sentry backend for Logger and it can handle the event
  message from the `Logger` event server and push the log message to the sentry
  dashboard.

  This module have a set of interface functions:

    * get/set the log level
    * get/set the log metadata

  ## Config

  Set the configuration for `:logger` as follow and the Sentry backend will
  push logging messages to the Sentry dashboard.

      config :logger,
        backends: [:console, Logger.Backends.File],
        sentry: [
          level: :error,
          metadata: []
        ]

  ### Suppressing Sentry logging

  When you want to suppress Sentry logging for a specific Logger call even if
  Sentry level is met to the level, pass following option:

      [logger_sentry: [skip_sentry: boolean]]

  For example, if Sentry level is set to `:error`, and you want to suppress
  Sentry logging for a specific error logging:

      Logger.error("error msg", [logger_sentry: [skip_sentry: true]])

  """

  @level_list [:debug, :info, :warning, :error]
  @metadata_list [:application, :module, :function, :file, :line, :pid]
  defstruct metadata: nil, level: nil, other_config: nil

  @doc """
  Get the backend log level.
  """
  @spec level :: :debug | :info | :warning | :error
  def level, do: :gen_event.call(Logger, __MODULE__, :level)

  @doc """
  Set the backend log level.
  """
  @spec level(:debug | :info | :warning | :error) :: :ok | :error_level
  def level(log_level) when log_level in @level_list do
    :gen_event.call(Logger, __MODULE__, {:level, log_level})
  end

  def level(_), do: :error_level

  @doc """
  Get the backend log metadata.
  """
  @spec metadata :: :all | list()
  def metadata, do: :gen_event.call(Logger, __MODULE__, :metadata)

  @doc """
  Set the backend log metadata.
  """
  @spec metadata(:all | list()) :: :error_metadata | :ok
  def metadata(:all) do
    :gen_event.call(Logger, __MODULE__, {:metadata, :all})
  end

  def metadata(meta_data) when is_list(meta_data) do
    case Enum.all?(meta_data, fn i -> Enum.member?(@metadata_list, i) end) do
      true -> :gen_event.call(Logger, __MODULE__, {:metadata, meta_data})
      false -> :error_metadata
    end
  end

  def metadata(_), do: :error_metadata

  @doc false
  def init(_) do
    config = Application.get_env(:logger, :sentry, [])
    {:ok, init(config, %__MODULE__{})}
  end

  @doc false
  def handle_call(:level, state) do
    {:ok, state.level, state}
  end

  def handle_call({:level, log_level}, state) do
    {:ok, :ok, %{state | level: log_level}}
  end

  def handle_call(:metadata, state) do
    {:ok, state.metadata, state}
  end

  def handle_call({:metadata, meta_data}, state) do
    {:ok, :ok, %{state | metadata: meta_data}}
  end

  @doc false
  def handle_event({level, _gl, {Logger, msg, _ts, md}}, %{level: log_level} = state) do
    # Get the Erlang level. This includes alert, critical, etc.
    {:erl_level, level} = List.keyfind(md, :erl_level, 0, {:erl_level, level})

    with true <- meet_level?(level, log_level),
         false <- skip_sentry?(md),
         options <- LoggerSentry.Sentry.generate_opts(md, msg),
         msg = format_message(msg) do
      send_sentry_log(level, msg, options)
    end

    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  @doc false
  def handle_info(_, state) do
    {:ok, state}
  end

  @doc false
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  @doc false
  def terminate(_reason, _state) do
    :ok
  end

  @doc false
  defp init(config, state) do
    meta_data =
      config
      |> Keyword.get(:metadata, [])
      |> configure_metadata()

    state
    |> Map.put(:metadata, meta_data)
    |> Map.put(:level, Keyword.get(config, :level, :info))
  end

  @doc false
  defp configure_metadata(:all), do: :all
  defp configure_metadata(meta_data), do: Enum.reverse(meta_data)

  @doc false
  defp meet_level?(_log_level, nil) do
    true
  end

  defp meet_level?(level, min) do
    Logger.compare_levels(level, min) != :lt
  end

  defp skip_sentry?(md) do
    md
    |> Keyword.get(:logger_sentry, [])
    |> Keyword.get(:skip_sentry, false)
  end

  defp format_message(msg) when is_binary(msg), do: msg

  defp format_message(msg) do
    IO.iodata_to_binary(msg)
  end

  if Mix.env() in [:test] do
    defp send_sentry_log(log_level, _output, options) do
      case :ets.info(:__just_prepare_for_logger_sentry__) do
        :undefined ->
          :ignore

        _ ->
          extra = Keyword.get(options, :extra)
          :ets.insert(:__just_prepare_for_logger_sentry__, {log_level, extra[:log_message]})
      end
    end
  else
    defp send_sentry_log(_log_level, output, options) do
      LoggerSentry.RateLimiter.send_rate_limited(output, options)
    end
  end
end
