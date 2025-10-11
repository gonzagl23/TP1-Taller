defmodule Ledger.Balance do
  @moduledoc """
  Funcionalidad para calcular y mostrar el balance de una cuenta.
  """

  alias Ledger.Repo
  alias Ledger.Transacciones
  alias Ledger.Monedas.Moneda
  alias Ledger.CSVParser

  def calcular(flags, _opts \\ []) do
    opciones = parsear_flags(flags)
    cuenta = Map.get(opciones, :cuenta_origen)
    moneda_destino = Map.get(opciones, :moneda_destino)
    archivo_salida = Map.get(opciones, :archivo_salida)
    archivo_transacciones = Map.get(opciones, :archivo_transacciones)

    if is_nil(cuenta) do
      IO.puts("Error: Debe especificarse el flag -c1")
      exit(:cuenta_invalida)
    end

    usar_csv = not is_nil(archivo_transacciones)

    transacciones =
      if usar_csv do
        CSVParser.leer_transacciones(archivo_transacciones)
      else
        Transacciones.obtener_transacciones_db()
      end

    opts_validacion = [usar_csv: usar_csv]

    case Transacciones.validar_y_filtrar(transacciones, nil, nil, opts_validacion) do
      {:error, errores} ->
        Enum.each(errores, &IO.puts/1)
        exit(:transacciones_invalidas)

      {:ok, transacciones_validas, _cuentas_altas} ->
        precios =
          if usar_csv do
            CSVParser.leer_monedas("monedas.csv")
          else
            Repo.all(Moneda)
            |> Enum.reduce(%{}, fn m, acc -> Map.put(acc, m.nombre_moneda, m.precio_dolares) end)
          end

        cuenta_str = to_string(cuenta)

        transacciones_cuenta =
          Enum.filter(transacciones_validas, fn t ->
            t.cuenta_origen == cuenta_str or t.cuenta_destino == cuenta_str
          end)

        balances =
          Enum.reduce(transacciones_cuenta, %{}, fn t, acc ->
            actualizar_balance(acc, t, cuenta_str, precios)
          end)

        balances_finales =
          if moneda_destino do
            case Map.fetch(precios, moneda_destino) do
              :error ->
                IO.puts("Moneda inválida: #{moneda_destino}")
                exit(:moneda_invalida)

              {:ok, precio_destino} ->
                total_usd =
                  Enum.reduce(balances, 0.0, fn {moneda, saldo}, suma ->
                    suma + saldo * Map.get(precios, moneda, 0)
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
  end

  defp actualizar_balance(balances, transaccion, cuenta_objetivo, precios) do
    case transaccion.tipo do
      "transferencia" ->
        moneda_origen = transaccion.moneda_origen
        moneda_destino = if transaccion.moneda_destino != "", do: transaccion.moneda_destino, else: moneda_origen

        balances
        |> actualizar_saldo(transaccion.cuenta_origen, moneda_origen, -transaccion.monto, cuenta_objetivo)
        |> actualizar_saldo(transaccion.cuenta_destino, moneda_destino, transaccion.monto, cuenta_objetivo)

      "deshacer" ->
        moneda_origen = transaccion.moneda_origen
        moneda_destino = if transaccion.moneda_destino != "", do: transaccion.moneda_destino, else: moneda_origen

        balances
        |> actualizar_saldo(transaccion.cuenta_origen, moneda_origen, -transaccion.monto, cuenta_objetivo)
        |> actualizar_saldo(transaccion.cuenta_destino, moneda_destino, transaccion.monto, cuenta_objetivo)

      "swap" ->
        moneda_origen = transaccion.moneda_origen
        moneda_destino = transaccion.moneda_destino
        precio_origen = Map.get(precios, moneda_origen, 0.0)
        precio_destino = Map.get(precios, moneda_destino, 0.0)
        monto_usd = transaccion.monto * precio_origen
        monto_convertido = if precio_destino == 0.0, do: 0.0, else: monto_usd / precio_destino

        balances
        |> actualizar_saldo(transaccion.cuenta_origen, moneda_origen, -transaccion.monto, cuenta_objetivo)
        |> actualizar_saldo(transaccion.cuenta_origen, moneda_destino, monto_convertido, cuenta_objetivo)

      "alta_cuenta" ->
        actualizar_saldo(balances, transaccion.cuenta_origen, transaccion.moneda_origen, transaccion.monto, cuenta_objetivo)

      _tipo_invalido ->
        balances
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
        ["-m", valor] -> Map.put(acc, :moneda_destino, valor)
        ["-o", valor] -> Map.put(acc, :archivo_salida, valor)
        ["-t", valor] -> Map.put(acc, :archivo_transacciones, valor)
        _flag_invalida -> acc
      end
    end)
  end
end
