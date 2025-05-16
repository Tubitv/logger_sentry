import Config

# Configure Sentry for the test environment
config :sentry,
  dsn: nil,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  environment_name: :test,
  included_environments: [:test],
  tags: %{
    env: "test"
  }
