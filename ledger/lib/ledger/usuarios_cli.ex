defmodule Ledger.UsuariosCLI do
  alias Ledger.Usuarios

  def crear(flags) do
    opts = parsear_flags(flags)

    case parse_fecha(opts[:fecha_nacimiento]) do
      {:ok, fecha} ->
        case Usuarios.crear_usuario(%{
              "nombre_usuario" => opts[:nombre_usuario],
              "fecha_nacimiento" => fecha
            }) do
          {:ok, usuario} ->
            IO.inspect(usuario)

          {:error, changeset} ->
            errores =
              changeset.errors
              |> Enum.map(fn {campo, {mensaje, _}} -> "#{campo}: #{mensaje}" end)
              |> Enum.join(",")

            IO.inspect({:error, :crear_usuario, errores})
        end

      {:error, msg} ->
        IO.inspect({:error, :crear_usuario, msg})
    end
  end

  def editar(flags) do
    opts = parsear_flags(flags)

    case Usuarios.ver_usuario(String.to_integer(opts[:id])) do
      {:ok, usuario} ->
        case Usuarios.editar_usuario(usuario, %{"nombre_usuario" => opts[:nombre_usuario]}) do
          {:ok, usuario} ->
            IO.inspect(usuario)

          {:error, changeset} ->
            errores =
              changeset.errors
              |> Enum.map(fn {campo, {mensaje, _}} -> "#{campo}: #{mensaje}" end)
              |> Enum.join(", ")

            IO.inspect({:error, :editar_usuario, errores})
        end

      {:error, _} ->
        IO.inspect({:error, :editar_usuario, "El usuario no existe"})
    end
  end

  def borrar(flags) do
    opts = parsear_flags(flags)

    case Usuarios.ver_usuario(String.to_integer(opts[:id])) do
      {:ok, usuario} ->
        case Usuarios.borrar_usuario(usuario) do
          {:ok, _} ->
            IO.puts("Usuario borrado correctamente")

          {:error, :usuario_con_transacciones} ->
            IO.inspect({:error, :borrar_usuario, "El usuario tiene transacciones asociadas"})
        end

      {:error, _} ->
        IO.inspect({:error, :borrar_usuario, "El usuario no existe"})
    end
  end


  def ver(flags) do
    opts = parsear_flags(flags)

    case Usuarios.ver_usuario(String.to_integer(opts[:id])) do
      {:ok, usuario} ->
        IO.inspect(usuario)

      {:error, _} ->
        IO.inspect({:error, :ver_usuario, "El usuario no existe"})
    end
  end


  defp parsear_flags(args) do
    Enum.reduce(args, %{}, fn arg, acc ->
      case String.split(arg, "=") do
        ["-n", valor] -> Map.put(acc, :nombre_usuario, valor)
        ["-b", valor] -> Map.put(acc, :fecha_nacimiento, valor)
        ["-id", valor] -> Map.put(acc, :id, valor)
        _ -> acc
      end
    end)
  end

  defp parse_fecha(str) do
    case Date.from_iso8601(str) do
      {:ok, fecha} -> {:ok, fecha}
      _ -> {:error, "Fecha invalida: #{str}"}
    end
  end

end
