# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :chess_town, ChessTownWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "fvrPxsmP/jkeWVyD+A5qPquY34/eMw6HMa3CXfR0CkqmFWzTszdLiQSZ3t4bDR4v",
  render_errors: [view: ChessTownWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ChessTown.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "t4SPhi4t"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
