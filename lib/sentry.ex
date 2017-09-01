defmodule Logger.Backends.Sentry do
  @moduledoc false

  @behaviour :gen_event
  @ets_table Elixir.Logger.Config
  @main_key :__logger_backends_sentry__
  @level_list [:debug, :info, :warn, :error]

  def level, do: :ets.lookup_element(@ets_table, {@main_key, :level}, 2)
  def level(level) when level in @level_list do
    :ets.insert(@ets_table, {{@main_key, :level}, level})
    :ok
  end
  def level(_), do: :error_level

  def format, do: :ets.lookup_element(@ets_table, {@main_key, :format}, 2)

  def metadata, do: :ets.lookup_element(@ets_table, {@main_key, :metadata}, 2)

  def init(_) do
    config = Application.get_env(:logger, :sentry)
    device = Keyword.get(config, :device, :user)

    if Process.whereis(device) do
      {:ok, init_do(config)}
    else
      {:error, :ignore}
    end
  end

  def handle_call(_, state) do
    {:ok, :ok, state}
  end

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, state) do
    case meet_level?(level, level()) do
      true ->
        log_event(level, msg, ts, md)
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

  defp init_do(config) do
    level = Keyword.get(config, :level, :info)
    format = Logger.Formatter.compile Keyword.get(config, :format)
    metadata = Keyword.get(config, :metadata, []) |> configure_metadata()
    :ets.insert(@ets_table, {{@main_key, :level}, level})
    :ets.insert(@ets_table, {{@main_key, :format}, format})
    :ets.insert(@ets_table, {{@main_key, :metadata}, metadata})
    :ok
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

if Mix.env() in [:test] do
  defp log_event(level, msg, ts, md) do
    output = format_event(level, msg, ts, md)
    case :ets.info(:__just_prepare_for_logger_sentry__) do
      :undefined ->
        :ignore
      _ ->
        :ets.insert(:__just_prepare_for_logger_sentry__, {level, output})
    end
    :ok
  end
else
  defp log_event(level, msg, ts, md) do
    output = format_event(level, msg, ts, md)
    Sentry.capture_exception(output, [stacktrace: :erlang.get_stacktrace(), event_source: __MODULE__])
    :ok
  end
end

  defp format_event(level, msg, ts, md) do
    keys = metadata()
    format = format()
    format
    |> Logger.Formatter.format(level, msg, ts, take_metadata(md, keys))
    |> :erlang.iolist_to_binary
  end

  defp take_metadata(metadata, :all), do: metadata
  defp take_metadata(metadata, keys) do
    Enum.reduce keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error     -> acc
      end
    end
  end

end
