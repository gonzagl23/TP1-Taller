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

    case Monedas.ver_moneda(String.to_integer(opts[:id])) do
      {:ok, moneda} ->
        case parse_precio(opts[:precio_dolares]) do
          {:ok, precio} ->
            case Monedas.editar_moneda(moneda, %{"precio_dolares" => precio}) do
              {:ok, moneda} ->
                IO.inspect(moneda)

              {:error, changeset} ->
                errores =
                  changeset.errors
                  |> Enum.map(fn {campo, {mensaje, _}} -> "#{campo}: #{mensaje}" end)
                  |> Enum.join(", ")

                IO.inspect({:error, :editar_moneda, errores})
            end

          {:error, msg} ->
            IO.inspect({:error, :editar_moneda, msg})
        end

      {:error, _} ->
        IO.inspect({:error, :editar_moneda, "La moneda no existe"})
    end
  end

  def borrar(flags) do
    opts = parsear_flags(flags)

    case Monedas.ver_moneda(String.to_integer(opts[:id])) do
      {:ok, moneda} ->
        case Monedas.borrar_moneda(moneda) do
          {:ok, _} ->
            IO.puts("Moneda borrada correctamente")

          {:error, :borrar_moneda, msg} ->
            IO.inspect({:error, :borrar_moneda, msg})

          {:error, :moneda_con_transacciones} ->
            IO.inspect({:error, :borrar_moneda, "La moneda tiene transacciones asociadas"})

          {:error, reason} ->
            IO.inspect({:error, :borrar_moneda, "No se pudo borrar la moneda: #{inspect(reason)}"})
        end

      {:error, _} ->
        IO.inspect({:error, :borrar_moneda, "La moneda no existe"})
    end
  end

  def ver(flags) do
    opts = parsear_flags(flags)

    case Monedas.ver_moneda(String.to_integer(opts[:id])) do
      {:ok, moneda} ->
        IO.inspect(moneda)

      {:error, _} ->
        IO.inspect({:error, :ver_moneda, "La moneda no existe"})
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
