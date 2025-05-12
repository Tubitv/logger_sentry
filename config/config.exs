import Config

config :logger_sentry,
  fingerprints_mods: [
    LoggerSentry.Fingerprint.MatchMessage,
    LoggerSentry.Fingerprint.CodeLocation
  ]

config :logger,
  backends: [:console, Logger.Backends.Sentry],
  sentry: [metadata: []]
