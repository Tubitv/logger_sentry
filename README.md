# LoggerSentry

[![Build Status](https://img.shields.io/travis/Tubitv/logger_sentry.svg?style=flat-square)](https://travis-ci.org/Tubitv/logger_sentry)
[![Coverage Status](https://coveralls.io/repos/github/Tubitv/logger_sentry/badge.svg)](https://coveralls.io/github/Tubitv/logger_sentry)
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
