defmodule LoggerSentry.Fingerprint.MatchMessage do
  @moduledoc """
  Default fingerprints from match error message.
  """

  def fingerprints(_, message) do
    message
    |> :erlang.iolist_to_binary()
    |> String.split(["\n", "  "], trim: true)
    |> Enum.map(&convert_error/1)
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

  defp convert_error("** (BadMapError) expected a map" <> _) do
    "(BadMapError) expected a map"
  end

  defp convert_error("** (EXIT) time out" <> _) do
    "(EXIT) time out"
  end

  defp convert_error("** (exit) bad return value" <> _) do
    "(exit) bad return value"
  end

  # message will be like:
  # ["Children ", inspect(id), " of Supervisor ", sup_name(sup), ?\s, sup_context(context)]
  # from elixir module `Logger.Translator`
  defp convert_error("** (exit) killed" <> _) do
    "(exit) killed"
  end

  # fallback
  defp convert_error(error) do
    cond do
      # db_connection application
      String.contains?(error, "(DBConnection.ConnectionError)") ->
        "DBConnection ConnectionError"

      # example: ** (Postgrex.Error) ERROR 23502 (not_null_violation):
      String.contains?(error, "(Postgrex.Error)") ->
        "Postgrex Error"

      # from https://github.com/elixir-ecto/postgrex/blob/master/lib/postgrex/protocol.ex#L2961
      Regex.match?(~r"Postgrex.Protocol #PID<\d+\.\d+\.\d+> could not cancel", error) ->
        "Postgrex could not cancel request"

      # from https://github.com/elixir-ecto/postgrex/blob/master/lib/postgrex/protocol.ex#L601
      Regex.match?(
        ~r"Postgrex.Protocol #PID<\d+\.\d+\.\d+> timed out because it was handshaking for longer than",
        error
      ) ->
        "Postgrex handshaking timeout"

      true ->
        nil
    end
  end

  # __end_of_module__
end
