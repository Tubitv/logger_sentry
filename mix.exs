defmodule LoggerSentry.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logger_sentry,
      version: "0.1.5",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      description: description(),
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:sentry, "~> 6.0"},
      {:excoveralls, "~> 0.7", only: :test},
      {:ex_doc, "~> 0.16", only: [:dev, :test]}
    ]
  end

  defp description() do
    "The Logger backend for Sentry."
  end

  defp package() do
    [
      name: "logger_sentry",
      maintainers: ["redink"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/adRise/logger_sentry"}
    ]
  end
end
