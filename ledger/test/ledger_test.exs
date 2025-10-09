defmodule LedgerTest do
  use ExUnit.Case
  alias Ledger.CSVParser
  alias Ledger.Transacciones
  alias Ledger.Balance
  alias Ledger.CLI


  test "muestra mensaje de uso cuando los argumentos son incorrectos" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        CLI.main(["argumento_incorrecto"])
      end)

    assert output =~ "Uso: ./ledger [Funcion] [flags]"
  end

  test "llama a Transacciones.listar con los flags correctos" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        CLI.main(["transacciones", "-t=casos_prueba/caso1.csv", "-c1=userA"])
      end)

    assert output =~ "userA"
  end

  test "llama a Balance.calcular con los flags correctos" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        CLI.main(["balance", "-c1=userA", "-t=transacciones.csv"])
      end)

    assert output =~ "USDT="
  end

  test "parser lee transacciones correctamente" do
    transacciones = CSVParser.leer_transacciones("casos_prueba/caso1.csv")

    [{:ok, transaccion} | _] = transacciones

    assert transaccion.id != nil
    assert transaccion.moneda_origen != nil
  end

  test "detecta transacciones inválidas" do
    transacciones = CSVParser.leer_transacciones("casos_prueba/caso6.csv")

    errores =
      Enum.filter(transacciones, fn
        {:error, _nro_linea} -> true
        _ -> false
      end)

    assert length(errores) > 0
  end

  test "parser lee monedas correctamente" do
    monedas = CSVParser.leer_monedas("monedas.csv")

    assert map_size(monedas) > 0
  end

  test "leer_monedas lanza detecta si hay precio inválido" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        catch_exit(
          Ledger.CSVParser.leer_monedas("casos_prueba/casos_moneda.csv")
        )
      end)

    assert output =~ "Error: No se pudo parsear el precio de ETH, valor inválido: oso"
  end

  test "la función listar(transacciones) imprime por pantalla lo esperado" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        Transacciones.listar(["-t=casos_prueba/caso2.csv"])
      end)

    assert output =~ "1;1006751404;USDT;;20000.000000;userA;;alta_cuenta"
    assert output =~ "2;1224751404;USDT;;100.000000;userB;;alta_cuenta"
    assert output =~ "3;1754937004;USDT;USDT;100.500000;userA;userB;transferencia"
  end

  test "La función listar(transacciones) detecta lineas mal formateadas" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        catch_exit(
          Transacciones.listar(["-t=casos_prueba/caso3.csv"])
        )
      end)

    assert output =~ "Error de formato en línea 5"
  end

  test "La función listar(transacciones) detecta Tipo de Transaccion invalida" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        catch_exit(
          Transacciones.listar(["-t=casos_prueba/caso7.csv"])
        )
      end)

    assert output =~ "Error en transaccion 1: Tipo de transaccion inválido: suma"
  end

  test "La función listar(transacciones) detecta monto negativo o cero" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        catch_exit(
          Transacciones.listar(["-t=casos_prueba/caso8.csv"])
        )
      end)

    assert output =~ "Error en transaccion 1: Monto negativo o cero"
  end


 test "Error cuando no se encuentra transacciones que coincidan con los filtros" do
  output =
    ExUnit.CaptureIO.capture_io(fn ->
      catch_exit(
        Transacciones.listar([
          "-t=transacciones.csv",
          "-c1=userA",
          "-c2=userT"
        ])
      )
    end)

    assert output =~ "Error: No se encontraron transacciones que coincidan con los filtros"
  end


  test "La función listar(transacciones) filtra por cuenta_origen y cuenta_destino correctamente" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        Transacciones.listar([
          "-t=casos_prueba/caso4.csv",
          "-c1=userA",
          "-c2=userB"
        ])
      end)

    assert output =~ "userA"
    assert output =~ "userB"
    refute output =~ "UserC"
  end

  test "La función listar(transacciones) guarda las transacciones en archivo de salida" do
    Transacciones.listar([
      "-t=casos_prueba/caso5.csv",
      "-c1=userA",
      "-c2=userB",
      "-o=casos_prueba/salida.csv"
    ])

    salida = File.read!("casos_prueba/salida.csv")
    assert salida =~ "3;1754937004;USDT;USDT;100.500000;userA;userB;transferencia"
    File.rm("casos_prueba/salida.csv")
  end

  test "calcula balance de userA y muestra por pantalla" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        Balance.calcular(["-c1=userA", "-t=transacciones.csv"])
      end)

    assert output =~ "ARS=833333.333333"
    assert output =~ "BTC=0.100000"
    assert output =~ "ETH=0.333333"
    assert output =~ "EUR=847.457627"
    assert output =~ "USDT=5799.300000"
  end

  test "calcular balance de userA y convierte balance a USDT correctamente" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        Balance.calcular(["-c1=userA", "-t=transacciones.csv", "-m=USDT"])
      end)

    assert output =~ "USDT=14299.300000"
  end

  test "guarda balance en archivo de salida" do
    Balance.calcular(["-c1=userA", "-t=transacciones.csv", "-o=casos_prueba/salida_balance.csv"])
    salida = File.read!("casos_prueba/salida_balance.csv")

    assert salida =~ "ARS=833333.333333"
    assert salida =~ "BTC=0.100000"
    assert salida =~ "ETH=0.333333"
    assert salida =~ "EUR=847.457627"
    assert salida =~ "USDT=5799.300000"

    File.rm("casos_prueba/salida_balance.csv")
  end


  test "calcular muestra error si moneda es inválida" do
    salida = ExUnit.CaptureIO.capture_io(fn ->
      catch_exit(
        Ledger.Balance.calcular(["-c1=userA", "-m=da", "-t=transacciones.csv",])
      )
    end)

    assert salida =~ "Moneda inválida: da"
  end



end
