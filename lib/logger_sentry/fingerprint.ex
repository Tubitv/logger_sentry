defmodule LoggerSentry.Fingerprint do
  @moduledoc """
  Default fingerprints.
  """

  @doc """
  Fetch the default fingerprints.
  """
  def fingerprints(fingerprints_mods, metadata, msg) do
    fingerprints_mods
    |> Enum.filter(fn mod ->
      Code.ensure_loaded?(mod) and function_exported?(mod, :fingerprints, 2)
    end)
    |> Enum.map(fn mod -> mod.fingerprints(metadata, msg) end)
    |> Enum.concat()
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
  rescue
    _ -> []
  end

  # __end_of_module__
end
