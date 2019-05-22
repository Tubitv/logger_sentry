defmodule Logger.Backends.Sentry do
  @moduledoc """
  This module is the sentry backend for Logger and it can handle the event
  message from the Logger event server and push the log message to the sentry
  dashboard. This module have a set of interface functions:

    * get/set the log level
    * get/set the log metadata

  ## Config

  config example:

      config :logger,
        backends: [:console, Logger.Backends.File],
        sentry: [level: :error,
                 metadata: []
                ]

  We set the Applicaton configure of `logger`, and add it to `backends` list,
  the set log level as needed. So we could execute Logger interface functions
  as usas, and the sentry backend will push log message to the sentry dashboard.
  """

  @level_list [:debug, :info, :warn, :error]
  @metadata_list [:application, :module, :function, :file, :line, :pid]
  defstruct metadata: nil, level: nil, other_config: nil

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

  def handle_event({level, _gl, {Logger, msg, _ts, md}}, %{level: log_level} = state) do
    case meet_level?(level, log_level) do
      true ->
        {:ok, log_event(level, md, msg, state)}

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
    metadata = Keyword.get(config, :metadata, []) |> configure_metadata()
    %{state | metadata: metadata, level: level}
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp meet_level?(_lvl, nil), do: true

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp normalize_level(:warn), do: "warning"
  defp normalize_level(level), do: to_string(level)

  if Mix.env() in [:test] do
    defp log_event(level, _metadata, msg, state) do
      case :ets.info(:__just_prepare_for_logger_sentry__) do
        :undefined ->
          :ignore

        _ ->
          :ets.insert(:__just_prepare_for_logger_sentry__, {level, msg})
      end

      state
    end
  else
    defp log_event(:error, metadata, msg, state) do
      Sentry.capture_exception(
        generate_output(:error, metadata, msg),
        generate_opts(metadata, msg)
      )

      state
    end

    defp log_event(level, metadata0, msg, state) do
      metadata = [{:level, normalize_level(level)} | metadata0]
      Sentry.capture_message(generate_output(level, metadata0, msg), generate_opts(metadata, msg))
      state
    end

    defp generate_output(level, metadata, msg) do
      msg = :erlang.iolist_to_binary(msg)

      case Keyword.get(metadata, :exception) do
        nil ->
          {output, _} = Exception.blame(level, msg, Keyword.get(metadata, :stacktrace, []))
          output

        exception ->
          exception
      end
    end

    defp generate_opts(metadata, msg) do
      case custom_fingerprints(metadata, msg) do
        nil ->
          [{:extra, generate_extra(metadata, msg)} | metadata]

        fingerprint ->
          case Keyword.get(metadata, :fingerprint) do
            nil ->
              [{:extra, generate_extra(metadata, msg)}, {:fingerprint, fingerprint} | metadata]

            old_fingerprint ->
              [{:extra, generate_extra(metadata, msg)} | metadata]
              |> Keyword.put(:fingerprint, old_fingerprint ++ fingerprint)
          end
      end
    end

    defp generate_extra(metadata, msg) do
      %{
        application: Keyword.get(metadata, :application),
        module: Keyword.get(metadata, :module),
        function: Keyword.get(metadata, :function),
        file: Keyword.get(metadata, :file),
        line: Keyword.get(metadata, :line),
        log_message: :erlang.iolist_to_binary(msg)
      }
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()
      |> Map.merge(Keyword.get(metadata, :extra, %{}))
    end

    defp custom_fingerprints(metadata, msg) do
      default_fingerprints =
        case Application.get_env(:logger_sentry, :enable_default_fingerprints) do
          true -> LoggerSentry.Fingerprint.fingerprints(metadata, msg)
          _ -> []
        end

      custom_fingerprints =
        case Application.get_env(:logger_sentry, :fingerprints_mod) do
          nil -> []
          fingerprints_mod -> fingerprints_mod.custom_fingerprints(metadata, msg) || []
        end

      case default_fingerprints ++ custom_fingerprints do
        [] -> nil
        tmp_list -> Enum.uniq(tmp_list)
      end
    end
  end
end
