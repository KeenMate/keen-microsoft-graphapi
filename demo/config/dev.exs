import Config

config :demo, DemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_only_secret_key_base_that_is_at_least_64_bytes_long_for_phoenix_to_accept_it_ok",
  live_reload: [
    patterns: [
      ~r"lib/demo_web/.*(ex|heex)$"
    ]
  ]
