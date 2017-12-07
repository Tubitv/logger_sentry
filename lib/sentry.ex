defmodule Logger.Backends.Sentry do

  @moduledoc """
  This module is the sentry backend for Logger and it can handle the event
  message from the Logger event server and push the log message to the sentry
  dashboard. This module have a set of interface functions:

    * get/set the log level
    * get the log format
    * get/set the log metadata

  ## Config

  config example:

      config :logger,
        backends: [:console, Logger.Backends.File],
        sentry: [level: :error,
                 format: "$message",
                 metadata: []
                ]

  We set the Applicaton configure of `logger`, and add it to `backends` list,
  the set log level as needed. So we could execute Logger interface functions
  as usas, and the sentry backend will push log message to the sentry dashboard.
  """

  @level_list [:debug, :info, :warn, :error]
  @metadata_list [:application, :module, :function, :file, :line, :pid]
  defstruct [format: nil, metadata: nil, level: nil, other_config: nil]

  @doc """
  Get the backend log level.
  """
  @spec level :: :debug | :info | :warn | :error
  def level, do: :gen_event.call(Logger, __MODULE__, :level)

  @doc """
  Set the backend log level.
  """
  @spec level(:debug | :info | :warn | :error) :: :ok | :error_level
  def level(level) when level in @level_list do
    :gen_event.call(Logger, __MODULE__, {:level, level})
  end
  def level(_), do: :error_level

  @doc """
  Get the backend log format.
  """
  @spec format :: list()
  def format, do: :gen_event.call(Logger, __MODULE__, :format)

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
  def metadata(metadata) when is_list(metadata) do
    case Enum.all?(metadata, fn i -> Enum.member?(@metadata_list, i) end) do
      true ->
        :gen_event.call(Logger, __MODULE__, {:metadata, metadata})
      false ->
        :error_metadata
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

  def handle_call({:level, level}, state) do
    {:ok, :ok, %{state | level: level}}
  end

  def handle_call(:format, state) do
    {:ok, state.format, state}
  end

  def handle_call(:metadata, state) do
    {:ok, state.metadata, state}
  end

  def handle_call({:metadata, metadata}, state) do
    {:ok, :ok, %{state | metadata: metadata}}
  end

  @doc false
  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}},
                   %{level: log_level} = state) do
    case meet_level?(level, log_level) do
      true ->
        {:ok, log_event(level, md, format_event(level, msg, ts, md, state), state)}
      _ ->
        {:ok, state}
    end
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

  # private functions
  defp init(config, state) do
    level = Keyword.get(config, :level, :info)
    format = Logger.Formatter.compile Keyword.get(config, :format)
    metadata = Keyword.get(config, :metadata, []) |> configure_metadata()
    %{state | format: format, metadata: metadata, level: level}
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp format_event(level, msg, ts, md, state) do
    %{metadata: keys, format: format} = state
    format
    |> Logger.Formatter.format(level, msg, ts, take_metadata(md, keys))
    |> :erlang.iolist_to_binary
  end

  defp take_metadata(_, []), do: []
  defp take_metadata(metadata, :all), do: metadata
  defp take_metadata(metadata, keys), do: Keyword.take(metadata, keys)

  defp meet_level?(_lvl, nil), do: true
  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

if Mix.env() in [:test] do
  defp log_event(level, _metadata, output, state) do
    case :ets.info(:__just_prepare_for_logger_sentry__) do
      :undefined ->
        :ignore
      _ ->
        :ets.insert(:__just_prepare_for_logger_sentry__, {level, output})
    end
    state
  end
else
  defp log_event(:error, metadata, output, state) do
    Sentry.capture_exception(output, metadata)
    state
  end
  defp log_event(_level, metadata, output, state) do
    Sentry.capture_message(output, metadata)
    state
  end
end

end
