defmodule LoggerSentry.Sentry do
  @moduledoc """
  Generate output and options for sentry.
  """

  @doc """
  Generate output.
  """
  @spec generate_output(atom, Keyword.t(), list()) :: {Exception.t(), Keyword.t()}
  def generate_output(level, metadata, message) do
    case Keyword.get(metadata, :crash_reason) do
      {reason, stacktrace} -> {reason, Keyword.put(metadata, :stacktrace, stacktrace)}
      _ -> generate_output_without_crash_reason(level, metadata, message)
    end
  end

  @doc false
  defp generate_output_without_crash_reason(level, metadata, message) do
    case Keyword.get(metadata, :exception) do
      nil ->
        {output, _} =
          Exception.blame(
            level,
            :erlang.iolist_to_binary(message),
            Keyword.get(metadata, :stacktrace, [])
          )

        {output, metadata}

      exception ->
        {exception, metadata}
    end
  end

  @doc """
  Generate options for sentry.
  """
  @spec generate_opts(Keyword.t(), list()) :: Keyword.t()
  def generate_opts(metadata, message) do
    metadata
    |> generate_opts_extra(message)
    |> generate_opts_fingerprints(message)
  end

  @doc false
  defp generate_opts_extra(metadata, msg) do
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
    |> case do
      empty when empty == %{} -> metadata
      other -> Keyword.put(metadata, :extra, other)
    end
  end

  @doc false
  defp generate_opts_fingerprints(metadata, msg) do
    case generate_fingerprints(metadata, msg) do
      [] -> metadata
      other -> Keyword.put(metadata, :fingerprint, other)
    end
  end

  @doc false
  defp generate_fingerprints(metadata, msg) do
    :logger_sentry
    |> Application.get_env(:fingerprints_mods, [])
    |> LoggerSentry.Fingerprint.fingerprints(metadata, msg)
    |> Kernel.++(Keyword.get(metadata, :fingerprint, []))
    |> case do
      [] -> []
      tmp -> Enum.uniq(tmp)
    end
  end

  # __end_of_module__
end
