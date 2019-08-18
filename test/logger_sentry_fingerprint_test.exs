defmodule LoggerSentry.Fingerprint.Test do
  use ExUnit.Case

  test "fetch default fingerprints" do
    assert [] == LoggerSentry.Fingerprint.fingerprints([], [], "error")
  end

  # __end_of_module__
end
