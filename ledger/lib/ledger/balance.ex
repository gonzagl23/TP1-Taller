defmodule Ledger.Balance do
  alias Ledger.CSVParser

  @moduledoc """
  Funcionalidad para calcular y mostrar el balance de una cuenta.
  """

  def calcular(flags) do
    opciones = parsear_flags(flags)
    cuenta = Map.get(opciones, :cuenta_origen)
    moneda_destino = Map.get(opciones, :moneda_destino)
    archivo_salida = Map.get(opciones, :archivo_salida)

    if is_nil(cuenta) do
      IO.puts("Error: Debe especificarse el flag -c1 con el número de cuenta")
      exit(:cuenta_invalida)
    end

    archivo_transacciones = Map.get(opciones, :archivo_transacciones, "transacciones.csv")
    transacciones = CSVParser.leer_transacciones(archivo_transacciones)
    precios = CSVParser.leer_monedas("monedas.csv")

    cuentas_altas =
      transacciones
      |> Enum.filter(fn {:ok, t} -> t.tipo == "alta_cuenta" end)
      |> Enum.map(fn {:ok, t} -> t.cuenta_origen end)
      |> MapSet.new()

    balances =
      Enum.reduce(transacciones, %{}, fn
        {:error, _linea}, acc -> acc
        {:ok, t}, acc ->
          actualizar_balance(acc, t, cuenta, precios, cuentas_altas)
      end)

    balances_finales =
      if moneda_destino do
        case Map.fetch(precios, moneda_destino) do
          :error ->
            IO.puts("Moneda destino inválida: #{moneda_destino}")
            exit(:moneda_invalida)

          {:ok, precio_destino} ->
            total_usd =
              Enum.reduce(balances, 0.0, fn {moneda, saldo}, suma ->
                precio_moneda = Map.get(precios, moneda, 0)
                suma + saldo * precio_moneda
              end)

            %{moneda_destino => total_usd / precio_destino}
        end
      else
        balances
      end

    if archivo_salida do
      guardar_balance_csv(balances_finales, archivo_salida)
    else
      mostrar_balance_por_pantalla(balances_finales)
    end
  end

  defp actualizar_balance(balances, transaccion, cuenta, precios, cuentas_altas) do
    case transaccion.tipo do
      "transferencia" ->
        if MapSet.member?(cuentas_altas, transaccion.cuenta_origen) and
           MapSet.member?(cuentas_altas, transaccion.cuenta_destino) do
          balances
          |> actualizar_saldo(transaccion.cuenta_origen, transaccion.moneda_origen, -transaccion.monto, cuenta)
          |> actualizar_saldo(transaccion.cuenta_destino, transaccion.moneda_destino, transaccion.monto, cuenta)
        else
          balances
        end

      "swap" ->
        if transaccion.cuenta_origen == cuenta and MapSet.member?(cuentas_altas, transaccion.cuenta_origen) do
          precio_origen = Map.get(precios, transaccion.moneda_origen, 0.0)
          precio_destino = Map.get(precios, transaccion.moneda_destino, 0.0)

          monto_usd = transaccion.monto * precio_origen
          monto_convertido = monto_usd / precio_destino

          balances
          |> actualizar_saldo(cuenta, transaccion.moneda_origen, -transaccion.monto, cuenta)
          |> actualizar_saldo(cuenta, transaccion.moneda_destino, monto_convertido, cuenta)
        else
          balances
        end

      "alta_cuenta" ->
        if MapSet.member?(cuentas_altas, transaccion.cuenta_origen) do
          actualizar_saldo(balances, transaccion.cuenta_origen, transaccion.moneda_origen, transaccion.monto, cuenta)
        else
          balances
        end

      _ -> balances
    end
  end

  defp actualizar_saldo(balances, cuenta_actual, moneda, monto, cuenta_objetivo) do
    if cuenta_actual == cuenta_objetivo do
      Map.update(balances, moneda, monto, fn saldo -> saldo + monto end)
    else
      balances
    end
  end

  defp mostrar_balance_por_pantalla(balances) do
    Enum.each(balances, fn {moneda, saldo} ->
      IO.puts("#{moneda}=#{:erlang.float_to_binary(saldo, decimals: 6)}")
    end)
  end

  defp guardar_balance_csv(balances, ruta_archivo) do
    File.open!(ruta_archivo, [:write], fn file ->
      Enum.each(balances, fn {moneda, saldo} ->
        IO.write(file, "#{moneda}=#{:erlang.float_to_binary(saldo, decimals: 6)}\n")
      end)
    end)
  end


  defp parsear_flags(args) do
    Enum.reduce(args, %{}, fn arg, acc ->
      case String.split(arg, "=") do
        ["-c1", valor] -> Map.put(acc, :cuenta_origen, valor)
        ["-m", valor]  -> Map.put(acc, :moneda_destino, valor)
        ["-o", valor]  -> Map.put(acc, :archivo_salida, valor)
        ["-t", valor]  -> Map.put(acc, :archivo_transacciones, valor)
        _ -> acc
      end
    end)
  end
end
