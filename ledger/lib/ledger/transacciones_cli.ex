defmodule Ledger.TransaccionesCLI do
  alias Ledger.TransaccionesDB

  def alta_cuenta(flags) do
    opts = parsear_flags(flags)

    case TransaccionesDB.alta_cuenta(%{
          "cuenta_origen_id" => String.to_integer(opts[:usuario]),
          "moneda_origen_id" => String.to_integer(opts[:moneda]),
          "monto" => parse_monto(opts[:monto]),
          "tipo" => "alta_cuenta"
        }) do
      {:ok, transaccion} -> IO.inspect(transaccion)
      {:error, changeset} -> mostrar_errores(:alta_cuenta, changeset)
    end
  end

  def realizar_transferencia(flags) do
    opts = parsear_flags(flags)

    case TransaccionesDB.realizar_transferencia(%{
          "cuenta_origen_id" => String.to_integer(opts[:origen]),
          "cuenta_destino_id" => String.to_integer(opts[:destino]),
          "moneda_origen_id" => String.to_integer(opts[:moneda_origen]),
          "moneda_destino_id" => String.to_integer(opts[:moneda_destino]),
          "monto" => parse_monto(opts[:monto]),
          "tipo" => "transferencia"
        }) do
      {:ok, transaccion} -> IO.inspect(transaccion)
      {:error, changeset} -> mostrar_errores(:realizar_transferencia, changeset)
    end
  end

  def realizar_swap(flags) do
    opts = parsear_flags(flags)

    case TransaccionesDB.realizar_swap(%{
          "cuenta_origen_id" => String.to_integer(opts[:usuario]),
          "moneda_origen_id" => String.to_integer(opts[:moneda_origen]),
          "moneda_destino_id" => String.to_integer(opts[:moneda_destino]),
          "monto" => parse_monto(opts[:monto]),
          "tipo" => "swap"
        }) do
      {:ok, transaccion} -> IO.inspect(transaccion)
      {:error, changeset} -> mostrar_errores(:realizar_swap, changeset)
    end
  end

  def deshacer_transaccion(flags) do
    opts = parsear_flags(flags)

    case TransaccionesDB.deshacer_transaccion(String.to_integer(opts[:id])) do
      {:ok, transaccion} -> IO.inspect(transaccion)
      {:error, _, mensaje} -> IO.inspect({:error, :deshacer_transaccion, mensaje})
    end
  end

  def ver_transaccion(flags) do
    opts = parsear_flags(flags)

    case TransaccionesDB.ver_transaccion(String.to_integer(opts[:id])) do
      {:ok, transaccion} -> IO.inspect(transaccion)
      {:error, _, mensaje} -> IO.inspect({:error, :ver_transaccion, mensaje})
    end
  end

  defp parsear_flags(args) do
    Enum.reduce(args, %{}, fn arg, acc ->
      case String.split(arg, "=") do
        ["-u", valor] -> Map.put(acc, :usuario, valor)
        ["-o", valor] -> Map.put(acc, :origen, valor)
        ["-d", valor] -> Map.put(acc, :destino, valor)
        ["-m", valor] -> Map.put(acc, :moneda, valor)
        ["-mo", valor] -> Map.put(acc, :moneda_origen, valor)
        ["-md", valor] -> Map.put(acc, :moneda_destino, valor)
        ["-mm", valor] -> Map.put(acc, :monto, valor)
        ["-id", valor] -> Map.put(acc, :id, valor)
        _ -> acc
      end
    end)
  end

  defp parse_monto(nil), do: {:error, "Falta el flag -mm (monto)"}
  defp parse_monto(str) do
    case Float.parse(str) do
      {num, ""} -> num
      {num, _resto} -> num
      :error -> {:error, "Monto invalido: #{str}"}
    end
  end

  defp mostrar_errores(comando, changeset) do
    errores =
      changeset.errors
      |> Enum.map(fn {campo, {mensaje, _}} -> "#{campo}: #{mensaje}" end)
      |> Enum.join(", ")

    IO.inspect({:error, comando, errores})
  end

end
