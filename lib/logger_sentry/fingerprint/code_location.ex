defmodule LoggerSentry.Fingerprint.CodeLocation do
  @moduledoc """
  Default fingerprints from code location.
  """

  def fingerprints(metadata, _msg) do
    file = Keyword.get(metadata, :file)
    line = Keyword.get(metadata, :line)

    if file && line do
      %{
        application: Keyword.get(metadata, :application),
        module: Keyword.get(metadata, :module),
        function: Keyword.get(metadata, :function),
        file: file,
        line: line
      }
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Enum.map(fn {k, v} ->
        "#{k}:#{v}"
      end)
    else
      case Keyword.get(metadata, :crash_reason) do
        {err, stacktrace} -> ["error:#{Exception.format(:error, err, stacktrace)}"]
        _ -> []
      end
    end
  rescue
    _ ->
      []
  end

  # __end_of_module__
end
