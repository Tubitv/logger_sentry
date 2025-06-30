defmodule LoggerSentry.Mixfile do
  use Mix.Project

  @source_url "https://github.com/Tubitv/logger_sentry"
  @version "0.8.1"

  def project do
    [
      app: :logger_sentry,
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {LoggerSentry.Application, []}
    ]
  end

  defp deps do
    [
      {:sentry, "~> 10.9"},
      {:jason, "~> 1.4"},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test]},
      {:mimic, "~> 1.5", only: :test}
    ]
  end

  defp package() do
    [
      description: "The Logger backend for Sentry.",
      name: "logger_sentry",
      maintainers: ["redink"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        LICENSE: [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "#{@version}",
      formatters: ["html"]
    ]
  end
end
