use Mix.Config

config :logger,
  backends: [:console, Logger.Backends.Sentry],
  sentry: [format: "$message",
           metadata: []
          ]

config :sentry,
  dsn: "your dsn",
  environment_name: :test,
  included_environments: [:test],
  tags: %{
    env: "test"
  }
