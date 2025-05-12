defmodule LoggerSentry.Fingerprint.CodeLocation.Test do
  @moduledoc false

  use ExUnit.Case
  alias LoggerSentry.Fingerprint.CodeLocation

  test "get empty" do
    assert [] == CodeLocation.fingerprints([], nil)
  end

  test "get file and line" do
    assert ["line:2", "file:1"] == CodeLocation.fingerprints([file: 1, line: 2], nil)
  end

  test "crash reason" do
    assert [msg] = CodeLocation.fingerprints([crash_reason: {:error, nil}], nil)
    assert msg =~ "error:** (ErlangError) Erlang error: :error"
  end

  # __end_of_module__
end
