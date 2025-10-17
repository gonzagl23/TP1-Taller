defmodule Ledger.TransaccionesCLI do
  alias Ledger.TransaccionesDB

  def alta_cuenta(flags) do
    opts = parsear_flags(flags)
    monto = parse_monto(opts[:monto])

    if match?({:error, _}, monto) do
      IO.inspect({:error, :alta_cuenta, "Monto invalido o faltante"})
    else
      case TransaccionesDB.alta_cuenta(%{
             "cuenta_origen_id" => String.to_integer(opts[:usuario]),
             "moneda_origen_id" => String.to_integer(opts[:moneda]),
             "monto" => monto,
             "tipo" => "alta_cuenta"
           }) do
        {:ok, transaccion} -> IO.inspect(transaccion)
        {:error, :alta_cuenta, mensaje} -> IO.inspect({:error, :alta_cuenta, mensaje})
        {:error, changeset} -> mostrar_errores(:alta_cuenta, changeset)
      end
    end
  end

  def realizar_transferencia(flags) do
    opts = parsear_flags(flags)
    monto = parse_monto(opts[:monto])

    if match?({:error, _mensaje}, monto) do
      IO.inspect({:error, :realizar_transferencia, "Monto invalido o faltante"})
    else
      case TransaccionesDB.realizar_transferencia(%{
            "cuenta_origen_id" => String.to_integer(opts[:origen]),
            "cuenta_destino_id" => String.to_integer(opts[:destino]),
            "moneda_id" => String.to_integer(opts[:moneda]),
            "monto" => monto
          }) do
        {:ok, transaccion} -> IO.inspect(transaccion)
        {:error, :realizar_transferencia, mensaje} -> IO.inspect({:error, :realizar_transferencia, mensaje})
        {:error, changeset} -> mostrar_errores(:realizar_transferencia, changeset)
      end
    end
  end

  def realizar_swap(flags) do
    opts = parsear_flags(flags)
    monto = parse_monto(opts[:monto])

    if match?({:error, _mensaje}, monto) do
      IO.inspect({:error, :realizar_swap, "Monto invalido o faltante"})
    else
      case TransaccionesDB.realizar_swap(%{
             "cuenta_origen_id" => String.to_integer(opts[:usuario]),
             "moneda_origen_id" => String.to_integer(opts[:moneda_origen]),
             "moneda_destino_id" => String.to_integer(opts[:moneda_destino]),
             "monto" => monto,
             "tipo" => "swap"
           }) do
        {:ok, transaccion} -> IO.inspect(transaccion)
        {:error, :realizar_swap, mensaje} -> IO.inspect({:error, :realizar_swap, mensaje})
        {:error, changeset} -> mostrar_errores(:realizar_swap, changeset)
      end
    end
  end

  def deshacer_transaccion(flags) do
    opts = parsear_flags(flags)

    case Integer.parse(opts[:id] || "") do
      {id, ""} ->
        case TransaccionesDB.deshacer_transaccion(id) do
          {:ok, transaccion} -> IO.inspect(transaccion)
          {:error, :deshacer_transaccion, mensaje} -> IO.inspect({:error, :deshacer_transaccion, mensaje})
        end

      :error ->
        IO.inspect({:error, :deshacer_transaccion, "ID inválido"})
    end
  end

  def ver_transaccion(flags) do
    opts = parsear_flags(flags)

    case Integer.parse(opts[:id] || "") do
      {id, ""} ->
        case TransaccionesDB.ver_transaccion(id) do
          {:ok, transaccion} -> mostrar_transaccion(transaccion)
          {:error, :ver_transaccion, mensaje} -> IO.puts("Error: #{mensaje}")
        end

      :error ->
        IO.puts("Error: ID inválido")
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
        ["-a", valor] -> Map.put(acc, :monto, valor)
        ["-id", valor] -> Map.put(acc, :id, valor)
        _flag_invalido -> acc
      end
    end)
  end

  defp parse_monto(nil), do: {:error, "Falta el flag -a (monto)"}

  defp parse_monto(str) do
    case Float.parse(str) do
      {num, ""} -> num
      {num, _cadena_restante} -> num
      :error -> {:error, "Monto invalido: #{str}"}
    end
  end

  defp mostrar_errores(comando, changeset) do
    errores =
      changeset.errors
      |> Enum.map(fn {campo, {mensaje, _info}} -> "#{campo}: #{mensaje}" end)
      |> Enum.join(", ")

    IO.inspect({:error, comando, errores})
  end

  defp mostrar_transaccion(t) do
    origen_usuario = t.cuenta_origen && t.cuenta_origen.nombre_usuario || "N/A"
    destino_usuario = t.cuenta_destino && t.cuenta_destino.nombre_usuario || "N/A"
    origen_moneda = t.moneda_origen && t.moneda_origen.nombre_moneda || "N/A"
    destino_moneda = t.moneda_destino && t.moneda_destino.nombre_moneda || "N/A"

    monto_str = format_monto(t.monto)

    IO.puts("""
    Transacción ##{t.id} (#{t.tipo})
      Monto: #{monto_str}
      Usuario origen: #{origen_usuario} (id: #{t.cuenta_origen_id})
      Usuario destino: #{destino_usuario} (id: #{t.cuenta_destino_id || "N/A"})
      Moneda origen: #{origen_moneda} (id: #{t.moneda_origen_id})
      Moneda destino: #{destino_moneda} (id: #{t.moneda_destino_id || "N/A"})
      Fecha creación: #{t.fecha_creacion}
    """)
  end

  defp format_monto(monto) when is_float(monto) do
    monto_str = :erlang.float_to_binary(monto, decimals: 6)
    monto_str
    |> String.trim_trailing("0")
    |> String.trim_trailing(".")
  end
end
