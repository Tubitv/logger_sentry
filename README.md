# LoggerSentry

The Logger backend for Sentry.

## Installation

The package can be installed as:

1. Add `logger_sentry` to your `mix.exs` file

```
def deps do
  [{:logger_sentry, github: "redink/logger_sentry"}]
end
```

2. Configure your config file, just like:

```
config :logger,
  backends: [:console, Logger.Backends.Sentry],
  sentry: [level: :error,
           format: "$time $metadata[$level] $levelpad$message",
           metadata: [:application, :module, :function, :file, :line, :pid] # :all
          ]

```

If you want keep `console` backend in Logger event server, you should set `backends` with `[:console, Logger.Backends.Sentry]`. And sentry backend just support three options:

- level
- format
- metadata

just like as `console` backend.

## Usage

Just like using Logger.

```
Logger.debug("this is one debug message")
Logger.info("this is one info message")
Logger.warn("this is one warning message")
Logger.error("this is one error message, if you set sentry logger level with `error`, the message will sent to your sentry server")
```

### get log level

```
Logger.Backends.Sentry.level
```

### set log level

```
Logger.Backends.Sentry.level(:error)
```

### get format

```
Logger.Backends.Sentry.format
```

### get metadata

```
Logger.Backends.Sentry.metadata
```

### set metadata

```
Logger.Backends.Sentry.metadata([])
Logger.Backends.Sentry.metadata(:all)
Logger.Backends.Sentry.metadata([:application, :module, :pid])
```
