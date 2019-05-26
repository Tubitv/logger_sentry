defmodule LoggerSentry.Fingerprint.MatchMessage.Test do
  @moduledoc false

  use ExUnit.Case

  alias LoggerSentry.Fingerprint.MatchMessage

  test "function clause error" do
    message = ["Erlang error", "\n  ** (FunctionClauseError) error"]

    assert ["(FunctionClauseError) no function clause matching"] ==
             nil
             |> MatchMessage.fingerprints(message)
             |> Enum.reject(&is_nil/1)
  end

  test "match error" do
    message = ["Erlang error", "\n  ** (MatchError) no match of right hand side vale: []"]

    assert ["(MatchError) no match of right hand side value"] ==
             nil
             |> MatchMessage.fingerprints(message)
             |> Enum.reject(&is_nil/1)

    message = ["Erlang error", "\n  ** (MatchError) no match of right hand side vale: 1"]

    assert ["(MatchError) no match of right hand side value"] ==
             nil
             |> MatchMessage.fingerprints(message)
             |> Enum.reject(&is_nil/1)
  end

  test "regex match postgrex protocol error" do
    message = [
      "Postgrex.Protocol #PID<0.12121.1> timed out because it was handshaking for longer than xxxxx"
    ]

    assert ["Postgrex handshaking timeout"] == MatchMessage.fingerprints(nil, message)
  end

  # __end_of_module__
end
