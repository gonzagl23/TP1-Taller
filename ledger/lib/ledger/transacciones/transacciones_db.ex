defmodule Ledger.TransaccionesDB do
  import Ecto.Query, warn: false
  alias Ledger.Repo
  alias Ledger.TransaccionesDB.Transaccion

  def alta_cuenta(attrs) do
    %Transaccion{}
    |> Transaccion.changeset_crear(attrs)
    |> Repo.insert()
  end

  def realizar_transferencia(attrs) do
    %Transaccion{}
    |> Transaccion.changeset_crear(attrs)
    |> Repo.insert()
  end

  def realizar_swap(attrs) do
    %Transaccion{}
    |> Transaccion.changeset_crear(attrs)
    |> Repo.insert()
  end

  def deshacer_transaccion(id_transaccion) do
    transaccion = Repo.get(Transaccion, id_transaccion)

    if transaccion do
      ultima_origen =
        Repo.one(
          from t in Transaccion,
            where: t.cuenta_origen_id == ^transaccion.cuenta_origen_id or t.cuenta_destino_id == ^transaccion.cuenta_origen_id,
            order_by: [desc: t.timestamp],
            limit: 1
        )

      ultima_destino =
        Repo.one(
          from t in Transaccion,
            where: t.cuenta_origen_id == ^transaccion.cuenta_destino_id or t.cuenta_destino_id == ^transaccion.cuenta_destino_id,
            order_by: [desc: t.timestamp],
            limit: 1
        )

      if ultima_origen.id != transaccion.id or ultima_destino.id != transaccion.id do
        {:error, :deshacer_transaccion, "No se puede deshacer, no es la última transacción de alguno de los usuarios"}
      else
        opuesta =
          %Transaccion{
            moneda_origen_id: transaccion.moneda_destino_id,
            moneda_destino_id: transaccion.moneda_origen_id,
            cuenta_origen_id: transaccion.cuenta_destino_id,
            cuenta_destino_id: transaccion.cuenta_origen_id,
            monto: transaccion.monto,
            tipo: "deshacer"
          }

        Repo.insert(opuesta)
      end
    else
      {:error, :deshacer_transaccion, "La transacción no existe"}
    end
  end


  def ver_transaccion(id) do
    case Repo.get(Transaccion, id) do
      nil -> {:error, :ver_transaccion, "La transaccion no existe"}
      transaccion -> {:ok, transaccion}
    end
  end
end
