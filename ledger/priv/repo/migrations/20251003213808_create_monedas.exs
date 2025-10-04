defmodule Ledger.Repo.Migrations.CreateMonedas do
  use Ecto.Migration

  def change do
    create table(:monedas) do
      add :nombre_moneda, :string, null: false
      add :precio_dolares, :float, null: false

      timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion)
    end

    create unique_index(:monedas, [:nombre_moneda])
  end
end
