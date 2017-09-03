defmodule LoggerSentry.Mixfile do
  use Mix.Project

  def project do
    [app: :logger_sentry,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:sentry, "~> 5.0"},
     {:excoveralls, "~> 0.5", only: :test},
     {:ex_doc, "~> 0.16", only: [:dev, :test]}]
  end
end
