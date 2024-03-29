import Config

config :logger_sentry,
  fingerprints_mods: [
    LoggerSentry.Fingerprint.MatchMessage,
    LoggerSentry.Fingerprint.CodeLocation
  ]

config :logger,
  backends: [:console, Logger.Backends.Sentry],
  sentry: [metadata: []]

config :sentry,
  dsn: "your dsn",
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  environment_name: :test,
  included_environments: [:test],
  tags: %{
    env: "test"
  }
