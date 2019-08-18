# LoggerSentry

[![Build Status](https://img.shields.io/travis/Tubitv/logger_sentry.svg?style=flat-square)](https://travis-ci.org/Tubitv/logger_sentry)
[![Hex.pm Version](https://img.shields.io/hexpm/v/logger_sentry.svg?style=flat-square)](https://hex.pm/packages/logger_sentry)

The Logger backend for Sentry.

## Installation

The package can be installed as:

1. Add `logger_sentry` to your `mix.exs` file

```elixir
def deps do
  [{:logger_sentry, "~> 0.1.0"}]
end
```

2. Configure your config file, just like:

```elixir
config :logger,
  backends: [:console, Logger.Backends.Sentry],
  sentry: [level: :error,
           metadata: [:application, :module, :function, :file, :line, :pid] # :all
          ]

```

If you want keep `console` backend in Logger event server, you should set `backends` with `[:console, Logger.Backends.Sentry]`. And sentry backend just support three options:

- level
- metadata

just like as `console` backend.

## Usage

Just like using Logger.

```elixir
Logger.debug("this is one debug message")
Logger.info("this is one info message")
Logger.warn("this is one warning message")
Logger.error("this is one error message, if you set sentry logger level with `error`, the message will sent to your sentry server")
```

### get log level

```elixir
Logger.Backends.Sentry.level
```

### set log level

```elixir
Logger.Backends.Sentry.level(:error)
```

### get metadata

```elixir
Logger.Backends.Sentry.metadata
```

### set metadata

```elixir
Logger.Backends.Sentry.metadata([])
Logger.Backends.Sentry.metadata(:all)
Logger.Backends.Sentry.metadata([:application, :module, :pid])
```

## fingerprints

For use fingerprints in sentry dashboard easily, `logger_sentry` support option to define generate fingerprints modules.
Now only support match error message and code location, and you can also self-define module to generate the fingerprints, just need define `fingerprints/2` function in your self-define module.
And you need set the option for `logger_sentry` application, just like:

```elixir
config :logger_sentry,
  fingerprints_mods: [
    LoggerSentry.Fingerprint.MatchMessage, # [code source](./lib/logger_sentry/fingerprint/match_message.ex)
    LoggerSentry.Fingerprint.CodeLocation, # [code source](./lib/logger_sentry/fingerprint/code_location.ex)
    Self.Define.Module
  ]
```

## Example

[use example](https://github.com/Tubitv/logger_sentry/wiki/Use-example)
