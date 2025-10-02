import Config

config :ledger, Ledger.Repo,
  database: "ledger_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :ledger, ecto_repos: [Ledger.Repo]
