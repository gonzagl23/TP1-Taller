defmodule Ledger.Transacciones do
  alias Ledger.CSVParser
  @moduledoc """
  Funcionalidad para listar transacciones.
  """

def listar(flags) do
  opciones = parsear_flags(flags)
  archivo_transacciones = Map.get(opciones, :archivo, "transacciones.csv")
  cuenta_origen = Map.get(opciones, :cuenta_origen)
  cuenta_destino = Map.get(opciones, :cuenta_destino)
  archivo_salida = Map.get(opciones, :archivo_salida)

  transacciones = CSVParser.leer_transacciones(archivo_transacciones)

  transacciones_validas =
    Enum.reduce(transacciones, [], fn
      {:error, numero_linea}, transacciones_acumuladas ->
        IO.puts("Error de formato en línea #{numero_linea}")
        transacciones_acumuladas

      {:ok, transaccion}, transacciones_acumuladas ->
        case validar_transaccion(transaccion) do
          :ok ->
            if aplicar_filtro_transaccion?(transaccion, cuenta_origen, cuenta_destino) do
              [transaccion | transacciones_acumuladas]
            else
              transacciones_acumuladas
            end

          {:error, id_transaccion, mensaje_error} ->
            IO.puts("Error en transaccion #{id_transaccion}: #{mensaje_error}")
            transacciones_acumuladas
        end
    end)
    |> Enum.reverse()

  if transacciones_validas == [] do
    IO.puts("Error: No se encontraron transacciones que coincidan con los filtros")
    System.halt(1)
  end

  if archivo_salida do
    guardar_transacciones_csv(transacciones_validas, archivo_salida)
  else
    mostrar_transacciones_por_pantalla(transacciones_validas)
  end
end


defp validar_transaccion(transaccion) do
  monedas = CSVParser.leer_monedas("monedas.csv")
  tipos_validos = ["transferencia", "swap", "alta_cuenta"]

  with true <- transaccion.tipo in tipos_validos
                 || {:error, transaccion.id, "Tipo de transaccion inválido: #{transaccion.tipo}"},
       true <- transaccion.monto > 0
                 || {:error, transaccion.id, "Monto negativo o cero"},
       true <- Map.has_key?(monedas, transaccion.moneda_origen)
                 || {:error, transaccion.id, "Moneda de origen inválida: #{transaccion.moneda_origen}"},
       true <- transaccion.moneda_destino == "" or Map.has_key?(monedas, transaccion.moneda_destino)
                 || {:error, transaccion.id, "Moneda de destino inválida: #{transaccion.moneda_destino}"},
       true <- (transaccion.tipo != "transferencia") or (transaccion.cuenta_origen != "" and transaccion.cuenta_destino != "")
                 || {:error, transaccion.id, "Transferencia debe tener cuenta_origen y cuenta_destino"},
       true <- (transaccion.tipo != "swap") or (transaccion.cuenta_origen != "" and transaccion.moneda_destino != "")
                 || {:error, transaccion.id, "Swap debe tener cuenta_origen y moneda_destino"},
       true <- (transaccion.tipo != "alta_cuenta") or (transaccion.cuenta_origen != "" and transaccion.monto > 0)
                 || {:error, transaccion.id, "Alta_cuenta debe tener cuenta_origen y monto positivo"}
  do
    :ok
  end
end


  defp parsear_flags(args) do
    Enum.reduce(args, %{}, fn arg, acc ->
      case String.split(arg, "=") do
        ["-c1", valor] -> Map.put(acc, :cuenta_origen, valor)
        ["-c2", valor] -> Map.put(acc, :cuenta_destino, valor)
        ["-t", valor]  -> Map.put(acc, :archivo, valor)
        ["-o", valor]  -> Map.put(acc, :archivo_salida, valor)
        _ -> acc
      end
    end)
  end

  defp aplicar_filtro_transaccion?(transaccion, cuenta_origen, cuenta_destino) do
    (is_nil(cuenta_origen) or transaccion.cuenta_origen == cuenta_origen) and
    (is_nil(cuenta_destino) or transaccion.cuenta_destino == cuenta_destino)
  end

  defp mostrar_transacciones_por_pantalla(transacciones) do
    Enum.each(transacciones, fn transaccion ->
      IO.puts(
        "#{transaccion.id};#{transaccion.fecha_hora};#{transaccion.moneda_origen};#{transaccion.moneda_destino};#{transaccion.monto};#{transaccion.cuenta_origen};#{transaccion.cuenta_destino};#{transaccion.tipo}"
      )
    end)
  end

  defp guardar_transacciones_csv(transacciones, ruta_archivo) do
    File.open!(ruta_archivo, [:write], fn file ->
      Enum.each(transacciones, fn transaccion ->
        IO.write(
          file,
          "#{transaccion.id};#{transaccion.fecha_hora};#{transaccion.moneda_origen};#{transaccion.moneda_destino};#{transaccion.monto};#{transaccion.cuenta_origen};#{transaccion.cuenta_destino};#{transaccion.tipo}\n"
        )
      end)
    end)
  end
end
