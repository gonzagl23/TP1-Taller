defmodule Ledger.Usuarios do
  import Ecto.Query, warn: false
  alias Ledger.Repo
  alias Ledger.Usuarios.Usuario
  alias Ledger.TransaccionesDB.Transaccion

  def crear_usuario(attrs) do
    %Usuario{}
    |> Usuario.changeset_crear(attrs)
    |> Repo.insert()
  end

  def ver_usuario(id) do
  case Repo.get(Usuario, id) do
    nil -> {:error, :ver_usuario, "El usuario no existe"}
    usuario -> {:ok, usuario}
    end
  end

  def editar_usuario(%Usuario{} = usuario, attrs) do
    usuario
    |> Usuario.changeset_editar(attrs)
    |> Repo.update()
  end

  def borrar_usuario(%Usuario{} = usuario) do
    tiene_transacciones =
      from(t in Transaccion,
      where: t.cuenta_origen_id == ^usuario.id or t.cuenta_destino_id == ^usuario.id,
      select: count(t.id)
      )
      |> Repo.one()

    if tiene_transacciones > 0 do
      {:error, :borrar_usuario, "El usuario tiene transacciones asociadas"}
    else
      Repo.delete(usuario)
    end
  end
end
