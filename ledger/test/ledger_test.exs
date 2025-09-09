defmodule LedgerTest do
  use ExUnit.Case
  alias Ledger.CSVParser
  alias Ledger.Transacciones
  alias Ledger.Balance
  alias Ledger.CLI

  test "muestra mensaje de uso cuando los argumentos son incorrectos" do
    output = ExUnit.CaptureIO.capture_io(fn ->
      CLI.main(["argumento_incorrecto"])
    end)

    assert output =~ "Uso: ./ledger [transacciones|balance] [flags]"
    end

  test "llama a Transacciones.listar con los flags correctos" do
    output = ExUnit.CaptureIO.capture_io(fn ->
      CLI.main(["transacciones", "-t=casos_prueba/caso5.csv", "-c1=userA"])
    end)

    assert output =~ "userA"
  end

  test "llama a Balance.calcular con los flags correctos" do
    output = ExUnit.CaptureIO.capture_io(fn ->
      CLI.main(["balance", "-c1=userA"])
    end)

    assert output =~ "USDT="
  end


  test "leer transacciones correctamente" do
    transacciones = CSVParser.leer_transacciones("casos_prueba/caso1.csv")

    [{:ok, transaccion} | _] = transacciones

    assert transaccion.id != nil
    assert transaccion.moneda_origen != nil
  end

  test "detecta transacciones inválidas" do
    transacciones = CSVParser.leer_transacciones("casos_prueba/caso1.csv")

    errores = Enum.filter(transacciones, fn
      {:error, _nro_linea} -> true
      _ -> false
    end)

    assert length(errores) > 0
  end

  test "leer monedas correctamente" do
    monedas = CSVParser.leer_monedas("monedas.csv")

    assert map_size(monedas) > 0
  end

  test "lee monedas lanza error si hay precio inválido" do
    assert_raise RuntimeError, ~r/Precio inválido en moneda ETH: asdc/, fn ->
      Ledger.CSVParser.leer_monedas("casos_prueba/casos_moneda.csv")
      end
  end

  test "la función listar(transacciones) imprime por pantalla lo esperado" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        Transacciones.listar(["-t=casos_prueba/caso2.csv"])
      end)

    assert output =~ "1;1754937004;USDT;USDT;100.5;userA;userB;transferencia"
    assert output =~ "2;1754936774;BTC;BTC;0.1;userA;userB;transferencia"
  end

  test "La función listar(transacciones) detecta lineas mal formateadas" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        Transacciones.listar(["-t=casos_prueba/caso3.csv"])
      end)

    assert output =~ "Error de formato en línea 4"
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
    Transacciones.listar(["-t=casos_prueba/caso5.csv", "-c1=userA","-c2=userB","-o=casos_prueba/salida.csv"])

    salida = File.read!("casos_prueba/salida.csv")
    assert salida =~ "3;1754937004;USDT;USDT;100.5;userA;userB;transferencia"
    File.rm("casos_prueba/salida.csv")
  end

  test "calcula balance de userA y muestra por pantalla" do
    output = ExUnit.CaptureIO.capture_io(fn ->
      Balance.calcular(["-c1=userA"])
    end)

    assert output =~ "ARS=833333.333333"
    assert output =~ "BTC=0.100000"
    assert output =~ "ETH=0.333333"
    assert output =~ "EUR=847.457627"
    assert output =~ "USDT=5799.300000"
  end

  test "calcular balance de userA y convierte balance a USDT correctamente" do
    output = ExUnit.CaptureIO.capture_io(fn ->
      Balance.calcular(["-c1=userA", "-m=USDT"])
    end)

    assert output =~ "USDT=14299.300000"
  end

  test "guarda balance en archivo de salida" do
    archivo_salida = "casos_prueba/salida_balance.csv"

    Balance.calcular(["-c1=userA", "-o=#{archivo_salida}"])
    contenido = File.read!(archivo_salida)

    assert contenido =~ "ARS=833333.333333"
    assert contenido =~ "BTC=0.100000"
    assert contenido =~ "ETH=0.333333"
    assert contenido =~ "EUR=847.457627"
    assert contenido =~ "USDT=5799.300000"

    File.rm(archivo_salida)
  end

  test "calcular muestra error si moneda destino es inválida" do
    salida =
      catch_exit(
        ExUnit.CaptureIO.capture_io(fn ->
          Ledger.Balance.calcular(["-c1=userA", "-m=da"])
        end)
      )
    assert salida == :moneda_invalida
  end




end
