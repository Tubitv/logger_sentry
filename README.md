# LoggerSentry

[![Build Status](https://img.shields.io/travis/Tubitv/logger_sentry.svg?style=flat-square)](https://travis-ci.org/Tubitv/logger_sentry)
[![Module Version](https://img.shields.io/hexpm/v/logger_sentry.svg?style=flat-square)](https://hex.pm/packages/logger_sentry)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg?style=flat-square)](https://hexdocs.pm/logger_sentry/)
[![Total Download](https://img.shields.io/hexpm/dt/logger_sentry.svg?style=flat-square)](https://hex.pm/packages/logger_sentry)
[![License](https://img.shields.io/hexpm/l/logger_sentry.svg?style=flat-square)](https://github.com/Tubitv/logger_sentry/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/Tubitv/logger_sentry.svg?style=flat-square)](https://github.com/Tubitv/logger_sentry/commits/master)

The `Logger` backend for [Sentry](https://sentry.io).

## Installation

The package can be installed as:

Add `:logger_sentry` to your `mix.exs` file:

```elixir
def deps do
  [
    {:logger_sentry, "~> 0.6.0"}
  ]
end
```

Configure your config file, just like:

```elixir
config :logger,
  backends: [:console, Logger.Backends.Sentry],
  sentry: [
    level: :error,
    metadata: [:application, :module, :function, :file, :line, :pid] # :all
  ]
```

If you want keep `:console` backend in Logger event server, you should set
`:backends` with `[:console, Logger.Backends.Sentry]`. Just like `:console`
backend, the sentry backend supports the same `:level` and `:metadata` options.

## Usage

Similar to `Logger`.

```elixir
Logger.debug("this is one debug message")
Logger.info("this is one info message")
Logger.warn("this is one warning message")

# if you set sentry logger level with `:error`, the message will sent to your
# sentry server
Logger.error("this is one error message")
```

### Get log level

```elixir
Logger.Backends.Sentry.level
```

### Set log level

```elixir
Logger.Backends.Sentry.level(:error)
```

### Get metadata

```elixir
Logger.Backends.Sentry.metadata
```

### Set metadata

```elixir
Logger.Backends.Sentry.metadata([])
Logger.Backends.Sentry.metadata(:all)
Logger.Backends.Sentry.metadata([:application, :module, :pid])
```

## Fingerprints

To use fingerprints in sentry dashboard, set `:logger_sentry` option to define
generate fingerprints modules:

```elixir
config :logger_sentry,
  fingerprints_mods: [
    LoggerSentry.Fingerprint.MatchMessage,
    LoggerSentry.Fingerprint.CodeLocation,
    MyApp.Fingerprint.MyModule
  ]
```

Only match error message, `LoggerSentry.Fingerprint.MatchMessage ` and code
location, `LoggerSentry.Fingerprint.CodeLocation ` are available by default
right now.

You can define your own module, for example, `MyApp.Fingerprint.MyModule`, by
adding a `fingerprints/2` function.

## Examples

See additional usage examples at [wiki](https://github.com/Tubitv/logger_sentry/wiki/Use-example).

## Rate Limiting

Sentry can be configured with a rate limit on the Sentry servers.
Any messages received faster than that limit will not be processed.
In order to avoid unnecessary traffic and potentially getting IP-blocked
by Sentry, it is recommended to add rate limiting on your own servers.

By default, `LoggerSentry` does not enforce rate limits. Rate limiting can be added through your project config files like this:

```
import Config

config :logger_sentry, LoggerSentry.RateLimiter,
    rate_limiter_module: LoggerSentry.RateLimiter.TokenBucket,
    rate_limiter_options: [token_count: 20, interval_ms: 60_000]
```

`LoggerSentry` comes with a simple token bucket algorithm.
You may add other rate-limiting algorithms by creating a module that
conforms to the `LoggerSentry.RateLimiter` module. Then setting
`rate_limiter_module` to your custom module.

## Copyright and License

Copyright (c) 2017 Taotao Lin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
