defmodule Ledger.TransaccionesDB.Transaccion do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ledger.Usuarios.Usuario
  alias Ledger.Monedas.Moneda

  schema "transacciones" do
    field :monto, :float
    field :tipo, :string
    field :timestamp, :naive_datetime, default: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    belongs_to :cuenta_origen, Usuario
    belongs_to :cuenta_destino, Usuario
    belongs_to :moneda_origen, Moneda
    belongs_to :moneda_destino, Moneda

    timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion)
  end

  def changeset_alta_cuenta(transaccion, attrs) do
    transaccion
    |> cast(attrs, [:cuenta_origen_id, :moneda_origen_id, :monto, :tipo])
    |> validate_required([:cuenta_origen_id, :moneda_origen_id, :monto, :tipo])
    |> validate_number(:monto, greater_than: 0)
    |> validate_inclusion(:tipo, ["alta_cuenta"])
  end

  def changeset_transferencia(transaccion, attrs) do
    transaccion
    |> cast(attrs, [:cuenta_origen_id, :cuenta_destino_id, :moneda_origen_id, :monto, :tipo])
    |> validate_required([:cuenta_origen_id, :cuenta_destino_id, :moneda_origen_id, :monto, :tipo])
    |> validate_number(:monto, greater_than: 0)
    |> validate_inclusion(:tipo, ["transferencia"])
  end


  def changeset_swap(transaccion, attrs) do
    transaccion
    |> cast(attrs, [:cuenta_origen_id, :moneda_origen_id, :moneda_destino_id, :monto, :tipo])
    |> validate_required([:cuenta_origen_id, :moneda_origen_id, :moneda_destino_id, :monto, :tipo])
    |> validate_number(:monto, greater_than: 0)
    |> validate_inclusion(:tipo, ["swap"])
  end

end
