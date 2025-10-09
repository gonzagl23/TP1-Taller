defmodule Ledger.MonedasCLI do
  alias Ledger.Monedas

  def crear(flags) do
    opts = parsear_flags(flags)

    case parse_precio(opts[:precio_dolares]) do
      {:ok, precio} ->
        case Monedas.crear_moneda(%{
               "nombre_moneda" => opts[:nombre_moneda],
               "precio_dolares" => precio
             }) do
          {:ok, moneda} ->
            IO.inspect(moneda)

          {:error, changeset} ->
            errores =
              changeset.errors
              |> Enum.map(fn {campo, {mensaje, _}} -> "#{campo}: #{mensaje}" end)
              |> Enum.join(", ")

            IO.inspect({:error, :crear_moneda, errores})
        end

      {:error, msg} ->
        IO.inspect({:error, :crear_moneda, msg})
    end
  end

  def editar(flags) do
    opts = parsear_flags(flags)

    if opts[:id] do
      id = String.to_integer(opts[:id])

      case parse_precio(opts[:precio_dolares]) do
        {:ok, nuevo_precio} ->
          case Monedas.ver_moneda(id) do
            {:ok, moneda} ->
              cambios = if nuevo_precio, do: %{precio_dolares: nuevo_precio}, else: %{}
              if cambios == %{} do
                IO.puts("No hay cambios para aplicar")
              else
                case Monedas.editar_moneda(moneda, cambios) do
                  {:ok, moneda_editada} ->
                    IO.puts("Moneda editada correctamente")
                    IO.inspect(moneda_editada)

                  {:error, changeset} ->
                    errores =
                      changeset.errors
                      |> Enum.map(fn {campo, {mensaje, _}} -> "#{campo}: #{mensaje}" end)
                      |> Enum.join(", ")

                    IO.inspect({:error, :editar_moneda, errores})
                end
              end

            {:error, :ver_moneda, msg} ->
              IO.puts(msg)
          end

        {:error, msg} ->
          IO.inspect({:error, :editar_moneda, msg})
      end
    else
      IO.puts("Falta el flag -id")
    end
  end

  def borrar(flags) do
    opts = parsear_flags(flags)

    if opts[:id] do
      id = String.to_integer(opts[:id])
      case Monedas.ver_moneda(id) do
        {:ok, moneda} ->
          case Monedas.borrar_moneda(moneda) do
            {:ok, _} -> IO.puts("Moneda borrada correctamente")
            {:error, :borrar_moneda, msg} -> IO.inspect({:error, :borrar_moneda, msg})
            {:error, reason} ->
              IO.inspect({:error, :borrar_moneda, "No se pudo borrar la moneda: #{inspect(reason)}"})
          end

        {:error, :ver_moneda, msg} ->
          IO.inspect({:error, :ver_moneda, msg})
      end
    else
      IO.puts("Falta el flag -id")
    end
  end

  def ver(flags) do
    opts = parsear_flags(flags)

    if opts[:id] do
      id = String.to_integer(opts[:id])
      case Monedas.ver_moneda(id) do
        {:ok, moneda} -> IO.inspect(moneda)
        {:error, :ver_moneda, msg} -> IO.puts(msg)
      end
    else
      IO.puts("Falta el flag -id")
    end
  end

  defp parsear_flags(args) do
    Enum.reduce(args, %{}, fn arg, acc ->
      case String.split(arg, "=") do
        ["-n", valor] -> Map.put(acc, :nombre_moneda, valor)
        ["-p", valor] -> Map.put(acc, :precio_dolares, valor)
        ["-id", valor] -> Map.put(acc, :id, valor)
        _ -> acc
      end
    end)
  end

  defp parse_precio(nil), do: {:error, "Falta el flag -p (precio)"}

  defp parse_precio(str) when is_binary(str) do
    case Float.parse(str) do
      {num, ""} -> {:ok, num}
      _ -> {:error, "Precio invalido: #{str}"}
    end
  end
end
