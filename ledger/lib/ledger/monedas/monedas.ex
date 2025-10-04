defmodule Ledger.Monedas do
  import Ecto.Query, warn: false
  alias Ledger.Repo
  alias Ledger.Monedas.Moneda
  alias Ledger.TransaccionesDB.Transaccion

  def crear_moneda(attrs) do
    %Moneda{}
    |> Moneda.changeset_crear(attrs)
    |> Repo.insert()
  end

  def ver_moneda(id) do
    case Repo.get(Moneda, id) do
      nil -> {:error, :ver_moneda, "La moneda no existe"}
      moneda -> {:ok, moneda}
    end
  end

  def editar_moneda(%Moneda{} = moneda, attrs) do
    moneda
    |> Moneda.changeset_editar(attrs)
    |> Repo.update()
  end

  def borrar_moneda(%Moneda{} = moneda) do
    tiene_transacciones =
      from(t in Transaccion,
        where: t.moneda_origen_id == ^moneda.id or t.moneda_destino_id == ^moneda.id,
        select: count(t.id)
      )
      |> Repo.one()

    if tiene_transacciones > 0 do
      {:error, :borrar_moneda, "La moneda tiene transacciones asociadas"}
    else
      Repo.delete(moneda)
    end
  end
end
