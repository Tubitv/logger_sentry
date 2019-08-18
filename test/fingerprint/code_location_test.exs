defmodule LoggerSentry.Fingerprint.CodeLocation.Test do
  @moduledoc false

  use ExUnit.Case
  alias LoggerSentry.Fingerprint.CodeLocation

  test "get empty" do
    assert [] == CodeLocation.fingerprints([], nil)
  end

  test "get file and line" do
    assert ["file:1", "line:2"] == CodeLocation.fingerprints([file: 1, line: 2], nil)
  end

  # __end_of_module__
end
