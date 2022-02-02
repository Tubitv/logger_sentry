defmodule LoggerSentry.RateLimiter.Strategy do
  @moduledoc """
  A struct holding common data for rate-limiting strategies.
  The `module` must be the name of a module that conforms to the
  `LoggerSentry.RateLimiter` behaviour. The `state` may be used
  however the module sees fit.
  """

  @enforce_keys [:module, :state]
  defstruct [:module, :state]

  @type t() :: %__MODULE__{module: atom(), state: any()}

  @spec new(atom(), any()) :: t()
  def new(module, state) when is_atom(module) do
    %__MODULE__{module: module, state: state}
  end
end
