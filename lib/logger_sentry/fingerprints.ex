defmodule LoggerSentry.Fingerprints do
  @moduledoc """
  Default fingerprints.
  """

  @doc """
  Fetch the default fingerprints.
  """
  def fingerprints(_metadata, msg) do
    msg
    |> :erlang.iolist_to_binary()
    |> String.split("\n")
    |> Enum.filter(fn i -> String.starts_with?(i, "** (") end)
  end
end
