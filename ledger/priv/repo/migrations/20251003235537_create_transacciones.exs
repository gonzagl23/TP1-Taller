defmodule Ledger.Repo.Migrations.CreateTransacciones do
  use Ecto.Migration

  def change do
    create table(:transacciones) do
      add :timestamp, :naive_datetime, null: false, default: fragment("NOW()")
      add :moneda_origen_id, references(:monedas, on_delete: :restrict), null: false
      add :moneda_destino_id, references(:monedas, on_delete: :restrict), null: true
      add :cuenta_origen_id, references(:usuarios, on_delete: :restrict), null: false
      add :cuenta_destino_id, references(:usuarios, on_delete: :restrict), null: true
      add :monto, :float, null: false
      add :tipo, :string, null: false

      timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion)
    end

    create index(:transacciones, [:moneda_origen_id])
    create index(:transacciones, [:moneda_destino_id])
    create index(:transacciones, [:cuenta_origen_id])
    create index(:transacciones, [:cuenta_destino_id])


  end
end
