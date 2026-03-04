# Load .env.test if it exists (credentials for integration tests)
MicrosoftGraph.Test.EnvLoader.load()

# Exclude integration tests by default.
# Run with:
#   mix test --include integration                  # app-only (client credentials)
#   mix test --include integration_delegated        # delegated (user token)
#   mix test --include integration --include integration_delegated  # both
ExUnit.start(exclude: [:integration, :integration_delegated])
