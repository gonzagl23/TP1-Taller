import Config

config :ledger, Ledger.Repo,
  database: "ledger_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
