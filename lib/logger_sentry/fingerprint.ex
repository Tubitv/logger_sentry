defmodule LoggerSentry.Fingerprint do
  @moduledoc """
  Default fingerprints.
  """

  alias LoggerSentry.Fingerprint.MatchMessage

  @doc """
  Fetch the default fingerprints.
  """
  def fingerprints(metadata, msg) do
    [MatchMessage]
    |> Enum.map(fn mod -> mod.fingerprints(metadata, msg) end)
    |> Enum.concat()
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
  end

  # __end_of_module__
end
