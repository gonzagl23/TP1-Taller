defmodule Ledger.TransaccionesDB do
  import Ecto.Query, warn: false
  alias Ledger.Repo
  alias Ledger.TransaccionesDB.Transaccion
  alias Ledger.Usuarios.Usuario
  alias Ledger.Monedas.Moneda

  def alta_cuenta(attrs) do
    cuenta_id = attrs["cuenta_origen_id"]
    moneda_id = attrs["moneda_origen_id"]

    existe_alta? =
      from(t in Transaccion,
        where: t.tipo == "alta_cuenta" and
               t.cuenta_origen_id == ^cuenta_id and
               t.moneda_origen_id == ^moneda_id,
        select: count(t.id)
      )
      |> Repo.one()
      |> Kernel.>(0)

    if existe_alta? do
      {:error, :alta_cuenta, "La cuenta para el usuario #{cuenta_id} y la moneda #{moneda_id} ya fue dada de alta"}
    else
      with {:ok, _usuario} <- validar_usuario(cuenta_id),
           {:ok, _moneda} <- validar_moneda(moneda_id) do
        %Transaccion{}
        |> Transaccion.changeset_alta_cuenta(attrs)
        |> Repo.insert()
      else
        {:error, mensaje} -> {:error, :alta_cuenta, mensaje}
      end
    end
  end

  def realizar_transferencia(attrs) do
    with {:ok, _origen} <- validar_usuario(attrs["cuenta_origen_id"]),
        {:ok, _destino} <- validar_usuario(attrs["cuenta_destino_id"]),
        {:ok, _moneda} <- validar_moneda(attrs["moneda_id"]),
        {:ok, _} <- validar_alta_cuenta(attrs["cuenta_origen_id"], attrs["moneda_id"]),
        {:ok, _} <- validar_alta_cuenta(attrs["cuenta_destino_id"], attrs["moneda_id"]) do
      %Transaccion{}
      |> Transaccion.changeset_transferencia(%{
          "cuenta_origen_id" => attrs["cuenta_origen_id"],
          "cuenta_destino_id" => attrs["cuenta_destino_id"],
          "moneda_origen_id" => attrs["moneda_id"],
          "monto" => attrs["monto"],
          "tipo" => "transferencia"
        })
      |> Repo.insert()
    else
      {:error, mensaje} -> {:error, :realizar_transferencia, mensaje}
    end
  end


  def realizar_swap(attrs) do
    with {:ok, _usuario} <- validar_usuario(attrs["cuenta_origen_id"]),
         {:ok, _moneda_origen} <- validar_moneda(attrs["moneda_origen_id"]),
         {:ok, _moneda_destino} <- validar_moneda(attrs["moneda_destino_id"]),
         {:ok, _} <- validar_alta_cuenta(attrs["cuenta_origen_id"], attrs["moneda_origen_id"]) do
      %Transaccion{}
      |> Transaccion.changeset_swap(attrs)
      |> Repo.insert()
    else
      {:error, mensaje} -> {:error, :realizar_swap, mensaje}
    end
  end

  def deshacer_transaccion(id_transaccion) do
    case Repo.get(Transaccion, id_transaccion) do
      nil ->
        {:error, :deshacer_transaccion, "La transacción no existe"}

      transaccion ->
        ultima_origen =
          from(t in Transaccion,
            where: t.cuenta_origen_id == ^transaccion.cuenta_origen_id or
                  t.cuenta_destino_id == ^transaccion.cuenta_origen_id,
            order_by: [desc: t.fecha_creacion],
            limit: 1
          )
          |> Repo.one()

        ultima_destino =
          if transaccion.cuenta_destino_id do
            from(t in Transaccion,
              where: t.cuenta_origen_id == ^transaccion.cuenta_destino_id or
                    t.cuenta_destino_id == ^transaccion.cuenta_destino_id,
              order_by: [desc: t.fecha_creacion],
              limit: 1
            )
            |> Repo.one()
          else
            nil
          end

        cond do
          ultima_origen.id != transaccion.id ->
            {:error, :deshacer_transaccion, "No se puede deshacer, no es la última transacción de la cuenta origen"}

          ultima_destino && ultima_destino.id != transaccion.id ->
            {:error, :deshacer_transaccion, "No se puede deshacer, no es la última transacción de la cuenta destino"}

          true ->
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
    end
  end


  def ver_transaccion(id) do
    case Repo.get(Transaccion, id) do
      nil -> {:error, :ver_transaccion, "La transaccion no existe"}
      transaccion ->
        transaccion = Repo.preload(transaccion, [:cuenta_origen, :cuenta_destino, :moneda_origen, :moneda_destino])
        {:ok, transaccion}
    end
  end

  defp validar_usuario(id) do
    case Repo.get(Usuario, id) do
      nil -> {:error, "El usuario #{id} no existe"}
      usuario -> {:ok, usuario}
    end
  end

  defp validar_moneda(id) do
    case Repo.get(Moneda, id) do
      nil -> {:error, "La moneda #{id} no existe"}
      moneda -> {:ok, moneda}
    end
  end

  defp validar_alta_cuenta(usuario_id, moneda_id) do
    existe =
      from(t in Transaccion,
        where: t.tipo == "alta_cuenta" and
               t.cuenta_origen_id == ^usuario_id and
               t.moneda_origen_id == ^moneda_id,
        select: count(t.id)
      )
      |> Repo.one()
      |> Kernel.>(0)

    if existe do
      {:ok, :dada_de_alta}
    else
      {:error, "La cuenta del usuario #{usuario_id} con moneda #{moneda_id} no está dada de alta"}
    end
  end
end
