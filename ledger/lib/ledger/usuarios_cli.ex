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
              |> Enum.map(fn {campo, {mensaje, _info}} -> "#{campo}: #{mensaje}" end)
              |> Enum.join(",")

            IO.inspect({:error, :crear_usuario, errores})
        end

      {:error, msg} ->
        IO.inspect({:error, :crear_usuario, msg})
    end
  end

  def editar(flags) do
    opts = parsear_flags(flags)

    case opts[:id] do
      nil ->
        IO.puts("Falta el flag -id=<id>")

      id_str ->
        case Integer.parse(id_str) do
          {id, ""} ->
            case Usuarios.ver_usuario(id) do
              {:ok, usuario} ->
                nuevo_nombre = opts[:nombre_usuario]

                cond do
                  is_nil(nuevo_nombre) ->
                    IO.puts("Falta el flag -n=<nombre_usuario>")

                  nuevo_nombre == usuario.nombre_usuario ->
                    IO.puts("El nombre de usuario debe ser distinto al anterior")

                  true ->
                    cambios = %{nombre_usuario: nuevo_nombre}
                    case Usuarios.editar_usuario(usuario, cambios) do
                      {:ok, usuario_editado} ->
                        IO.puts("Usuario editado correctamente")
                        IO.inspect(usuario_editado)

                      {:error, changeset} ->
                        IO.inspect(changeset.errors, label: "Errores al editar")
                    end
                end

              {:error, :ver_usuario, _msg} ->
                IO.puts("El usuario no existe")
            end

          :error ->
            IO.puts("ID invalido")
        end
    end
  end

  def borrar(flags) do
    opts = parsear_flags(flags)

    case opts[:id] do
      nil ->
        IO.puts("Falta el flag -id=<id>")

      id_str ->
        case Integer.parse(id_str) do
          {id, ""} ->
            case Usuarios.ver_usuario(id) do
              {:ok, usuario} ->
                case Usuarios.borrar_usuario(usuario) do
                  {:ok, _} ->
                    IO.puts("Usuario borrado correctamente")

                  {:error, :borrar_usuario, mensaje} ->
                    IO.puts("No se puede borrar el usuario: #{mensaje}")
                end

              {:error, :ver_usuario, _msg} ->
                IO.puts("No se puede borrar el usuario: el usuario no existe")
            end

          :error ->
            IO.puts("ID invalido")
        end
    end
  end

  def ver(flags) do
    opts = parsear_flags(flags)

    case opts[:id] do
      nil ->
        IO.puts("Falta el flag -id=<id>")

      id_str ->
        case Integer.parse(id_str) do
          {id, ""} ->
            case Usuarios.ver_usuario(id) do
              {:ok, usuario} -> IO.inspect(usuario)
              {:error, _tipo, mensaje} -> IO.puts("Error: #{mensaje}")
            end

          :error ->
            IO.puts("ID invalido")
        end
    end
  end

  defp parsear_flags(args) do
    Enum.reduce(args, %{}, fn arg, acc ->
      case String.split(arg, "=") do
        ["-n", valor] -> Map.put(acc, :nombre_usuario, valor)
        ["-b", valor] -> Map.put(acc, :fecha_nacimiento, valor)
        ["-id", valor] -> Map.put(acc, :id, valor)
        _flag_invalido -> acc
      end
    end)
  end

  defp parse_fecha(str) do
    case Date.from_iso8601(str) do
      {:ok, fecha} -> {:ok, fecha}
      _fecha_invalida -> {:error, "Fecha invalida: #{str}"}
    end
  end
end
