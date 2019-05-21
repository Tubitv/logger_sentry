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
    |> String.split(["\n", "  "], trim: true)
    |> Enum.map(&convert_error/1)
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
  end

  @doc false
  defp convert_error("** (FunctionClauseError)" <> _) do
    "(FunctionClauseError) no function clause matching"
  end

  defp convert_error("** (MatchError)" <> _) do
    "(MatchError) no match of right hand side value"
  end

  defp convert_error("** (UndefinedFunctionError)" <> _) do
    "UndefinedFunctionError"
  end

  defp convert_error("** (KeyError) key" <> _) do
    "KeyError"
  end

  defp convert_error("** (EXIT) time out" <> _) do
    "(EXIT) time out"
  end

  # db connection
  defp convert_error("** (exit) %DBConnection.ConnectionError" <> _) do
    "(exit) DBConnection ConnectionError"
  end

  defp convert_error("** (DBConnection.ConnectionError)" <> _) do
    "(exit) DBConnection ConnectionError"
  end

  # fallback
  defp convert_error(error) do
    cond do
      String.contains?(error, "** (DBConnection.ConnectionError)") ->
        "(exit) DBConnection ConnectionError"

      true ->
        nil
    end
  end

  # __end_of_module__
end
