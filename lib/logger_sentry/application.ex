defmodule LoggerSentry.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: LoggerSentry.Supervisor]
    rate_limit_options = Application.get_env(:logger_sentry, LoggerSentry.RateLimiter, [])

    children = [
      {Task.Supervisor, name: LoggerSentry.TaskSupervisor},
      {LoggerSentry.RateLimiter, rate_limit_options}
    ]

    Supervisor.start_link(children, opts)
  end
end
