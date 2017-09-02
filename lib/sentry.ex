defmodule Logger.Backends.Sentry do
  @moduledoc false

  @behaviour :gen_event
  @level_list [:debug, :info, :warn, :error]
  @metadata_list [:application, :module, :function, :file, :line, :pid]

  defstruct [format: nil, metadata: nil, level: nil]

  @doc """
  Get Sentry log level
  """
  @spec level :: :debug | :info | :warn | :error
  def level, do: :gen_event.call(Logger, __MODULE__, :level)

  @doc """
  Set Sentry log level
  """
  @spec level(:debug | :info | :warn | :error) :: :ok | :error_level
  def level(level) when level in @level_list do
    :gen_event.call(Logger, __MODULE__, {:level, level})
  end
  def level(_), do: :error_level

  @doc """
  Get Sentry format
  """
  @spec format :: list()
  def format, do: :gen_event.call(Logger, __MODULE__, :format)

  @doc """
  Get Sentry metadata
  """
  @spec metadata :: :all | list()
  def metadata, do: :gen_event.call(Logger, __MODULE__, :metadata)

  @doc """
  Set Sentry metadata
  """
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

  def init(_) do
    config = Application.get_env(:logger, :sentry)
    device = Keyword.get(config, :device, :user)

    if Process.whereis(device) do
      {:ok, init(config, %__MODULE__{})}
    else
      {:error, :ignore}
    end
  end

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

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}},
                   %{level: log_level} = state) do
    case meet_level?(level, log_level) do
      true ->
        log_event(level, msg, ts, md, state)
      _ ->
        :ignore
    end
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  ## Helpers

  defp meet_level?(_lvl, nil), do: true

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp init(config, state) do
    level = Keyword.get(config, :level, :info)
    format = Logger.Formatter.compile Keyword.get(config, :format)
    metadata = Keyword.get(config, :metadata, []) |> configure_metadata()
    %{state | format: format, metadata: metadata, level: level}
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

if Mix.env() in [:test] do
  defp log_event(level, msg, ts, md, state) do
    output = format_event(level, msg, ts, md, state)
    case :ets.info(:__just_prepare_for_logger_sentry__) do
      :undefined ->
        :ignore
      _ ->
        :ets.insert(:__just_prepare_for_logger_sentry__, {level, output})
    end
    :ok
  end
else
  defp log_event(level, msg, ts, md, state) do
    output = format_event(level, msg, ts, md, state)
    Sentry.capture_exception(output, [stacktrace: :erlang.get_stacktrace(),
                                      event_source: __MODULE__])
    :ok
  end
end

  defp format_event(level, msg, ts, md, state) do
    %{metadata: keys, format: format} = state
    format
    |> Logger.Formatter.format(level, msg, ts, take_metadata(md, keys))
    |> :erlang.iolist_to_binary
  end

  def take_metadata(_, []), do: []
  def take_metadata(metadata, :all), do: metadata
  def take_metadata(metadata, keys), do: Keyword.take(metadata, keys)

end
