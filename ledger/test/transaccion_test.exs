defmodule Ledger.TransaccionesTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Ledger.Repo
  alias Ledger.Usuarios
  alias Ledger.Monedas
  alias Ledger.TransaccionesDB
  alias Ledger.TransaccionesDB.Transaccion

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  defp crear_usuario(nombre, fecha \\ ~D[1990-01-01]) do
    {:ok, u} = Usuarios.crear_usuario(%{"nombre_usuario" => nombre, "fecha_nacimiento" => fecha})
    u
  end

  defp crear_moneda(nombre, precio \\ 100.00) do
    {:ok, m} = Monedas.crear_moneda(%{"nombre_moneda" => nombre, "precio_dolares" => precio})
    m
  end

  describe "alta_cuenta/1" do
    test "crea alta_cuenta válida" do
      u = crear_usuario("Gonzalo")
      m = crear_moneda("USD")

      attrs = %{"cuenta_origen_id" => u.id, "moneda_origen_id" => m.id, "monto" => 1000.00, "tipo" => "alta_cuenta"}
      assert {:ok, %Transaccion{} = tx} = TransaccionesDB.alta_cuenta(attrs)
      assert tx.tipo == "alta_cuenta"
      assert tx.cuenta_origen_id == u.id
      assert tx.moneda_origen_id == m.id
    end

    test "error por monto inválido (<=0) en alta_cuenta" do
      u = crear_usuario("Lucas")
      m = crear_moneda("EUR")

      attrs = %{"cuenta_origen_id" => u.id, "moneda_origen_id" => m.id, "monto" => -10.00, "tipo" => "alta_cuenta"}
      assert {:error, :alta_cuenta, _} = TransaccionesDB.alta_cuenta(attrs)
    end

    test "no permite alta duplicada" do
      u = crear_usuario("Paul")
      m = crear_moneda("BTC")

      attrs = %{"cuenta_origen_id" => u.id, "moneda_origen_id" => m.id, "monto" => 1.0, "tipo" => "alta_cuenta"}
      assert {:ok, _} = TransaccionesDB.alta_cuenta(attrs)
      assert {:error, :alta_cuenta, _mensaje} = TransaccionesDB.alta_cuenta(attrs)
    end
  end

  describe "realizar_transferencia/1" do
    test "realiza transferencia cuando ambas cuentas están dadas de alta" do
      u1 = crear_usuario("Gonza")
      u2 = crear_usuario("Paul")
      m = crear_moneda("USD")

      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u1.id, "moneda_origen_id" => m.id, "monto" => 100.0, "tipo" => "alta_cuenta"})
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u2.id, "moneda_origen_id" => m.id, "monto" => 100.0, "tipo" => "alta_cuenta"})

      attrs = %{
        "cuenta_origen_id" => u1.id,
        "cuenta_destino_id" => u2.id,
        "moneda_id" => m.id,
        "monto" => 50.0
      }

      assert {:ok, %Transaccion{} = tx} = TransaccionesDB.realizar_transferencia(attrs)
      assert tx.tipo == "transferencia"
      assert tx.cuenta_origen_id == u1.id
      assert tx.cuenta_destino_id == u2.id
    end

    test "error si alguna cuenta no está dada de alta" do
      u1 = crear_usuario("Garcia")
      u2 = crear_usuario("Lopez")
      m = crear_moneda("EUR")

      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u1.id, "moneda_origen_id" => m.id, "monto" => 50.0, "tipo" => "alta_cuenta"})

      attrs = %{
        "cuenta_origen_id" => u1.id,
        "cuenta_destino_id" => u2.id,
        "moneda_id" => m.id,
        "monto" => 10.0
      }

      assert {:error, :realizar_transferencia, _} = TransaccionesDB.realizar_transferencia(attrs)
    end
  end

  describe "realizar_swap/1" do
    test "realiza swap válido" do
      u = crear_usuario("Gonzalito")
      m1 = crear_moneda("USD")
      m2 = crear_moneda("BTC")

      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u.id, "moneda_origen_id" => m1.id, "monto" => 100.00, "tipo" => "alta_cuenta"})
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u.id, "moneda_origen_id" => m2.id, "monto" => 100.00, "tipo" => "alta_cuenta"})

      attrs = %{
        "cuenta_origen_id" => u.id,
        "moneda_origen_id" => m1.id,
        "moneda_destino_id" => m2.id,
        "monto" => 5.0
      }

      assert {:ok, %Transaccion{} = tx} = TransaccionesDB.realizar_swap(attrs)
      assert tx.tipo == "swap"
      assert tx.moneda_origen_id == m1.id
      assert tx.moneda_destino_id == m2.id
    end
  end

  describe "deshacer_transaccion/1" do
    test "error si la transacción no existe" do
      assert {:error, :deshacer_transaccion, _} = TransaccionesDB.deshacer_transaccion(50)
    end

    test "error si no es la última transacción de la cuenta origen o destino" do
      u = crear_usuario("Miguel")
      m = crear_moneda("USD")

      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})

      otro = crear_usuario("Lolo")
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => otro.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})

      {:ok, tx1} = TransaccionesDB.realizar_transferencia(%{"cuenta_origen_id" => u.id, "cuenta_destino_id" => otro.id, "moneda_id" => m.id, "monto" => 1.0})
      {:ok, _tx2} = TransaccionesDB.realizar_transferencia(%{"cuenta_origen_id" => u.id, "cuenta_destino_id" => otro.id, "moneda_id" => m.id, "monto" => 2.0})

      assert {:error, :deshacer_transaccion, _} = TransaccionesDB.deshacer_transaccion(tx1.id)
    end

    test "deshace transacción correctamente (inserta opuesta) cuando es la última" do
      u = crear_usuario("Coco")
      otro = crear_usuario("User")
      m = crear_moneda("USD")

      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => otro.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})

      {:ok, tx} = TransaccionesDB.realizar_transferencia(%{"cuenta_origen_id" => u.id, "cuenta_destino_id" => otro.id, "moneda_id" => m.id, "monto" => 3.0})

      assert {:ok, %Transaccion{} = opuesta} = TransaccionesDB.deshacer_transaccion(tx.id)
      assert opuesta.tipo == "deshacer"
      assert opuesta.cuenta_origen_id == tx.cuenta_destino_id
      assert opuesta.cuenta_destino_id == tx.cuenta_origen_id
    end
  end

  describe "ver_transaccion/1" do
    test "devuelve transacción existente" do
      u = crear_usuario("V1")
      otro = crear_usuario("V2")
      m = crear_moneda("USD")

      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => otro.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})

      {:ok, tx} = TransaccionesDB.realizar_transferencia(%{"cuenta_origen_id" => u.id, "cuenta_destino_id" => otro.id, "moneda_id" => m.id, "monto" => 4.0})

      assert {:ok, %Transaccion{} = t} = TransaccionesDB.ver_transaccion(tx.id)
      assert t.id == tx.id
      assert Map.has_key?(t, :cuenta_origen)
      assert Map.has_key?(t, :moneda_origen)
    end

    test "error si no existe" do
      assert {:error, :ver_transaccion, _} = TransaccionesDB.ver_transaccion(9)
    end
  end

  describe "TransaccionesCLI" do
    test "alta_cuenta CLI éxito" do
      u = crear_usuario("user")
      m = crear_moneda("USD")

      output = capture_io(fn ->
        Ledger.CLI.main(["alta_cuenta", "-u=#{u.id}", "-m=#{m.id}", "-a=10.0"])
      end)

      assert output =~ "alta_cuenta" or output =~ "#{u.id}"
    end

    test "alta_cuenta CLI monto inválido" do
      u = crear_usuario("user1")
      m = crear_moneda("BTC")

      output = capture_io(fn ->
        Ledger.CLI.main(["alta_cuenta", "-u=#{u.id}", "-m=#{m.id}", "-a=notanumber"])
      end)

      assert output =~ "Monto invalido" or output =~ "Falta el flag"
    end

    test "realizar_transferencia CLI éxito" do
      u1 = crear_usuario("user1")
      u2 = crear_usuario("user2")
      m = crear_moneda("USD")
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u1.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u2.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})

      output = capture_io(fn ->
        Ledger.CLI.main(["realizar_transferencia", "-o=#{u1.id}", "-d=#{u2.id}", "-m=#{m.id}", "-a=2.5"])
      end)

      assert output =~ "transferencia" or output =~ "#{u1.id}"
    end

    test "realizar_swap CLI éxito" do
      u = crear_usuario("user")
      m1 = crear_moneda("USD")
      m2 = crear_moneda("BTC")
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u.id, "moneda_origen_id" => m1.id, "monto" => 0.1, "tipo" => "alta_cuenta"})

      output = capture_io(fn ->
        Ledger.CLI.main(["realizar_swap", "-u=#{u.id}", "-mo=#{m1.id}", "-md=#{m2.id}", "-a=1.5"])
      end)

      assert output =~ "swap" or output =~ "#{u.id}"
    end

    test "deshacer_transaccion CLI éxito" do
      u = crear_usuario("Tomas")
      otro = crear_usuario("Thony")
      m = crear_moneda("USD")

      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => otro.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})

      {:ok, tx} = TransaccionesDB.realizar_transferencia(%{"cuenta_origen_id" => u.id, "cuenta_destino_id" => otro.id, "moneda_id" => m.id, "monto" => 2.0})

      output = capture_io(fn ->
        Ledger.CLI.main(["deshacer_transaccion", "-id=#{tx.id}"])
      end)

      assert output =~ "deshacer" or output =~ "#{tx.id}"
    end

    test "ver_transaccion CLI muestra datos" do
      u = crear_usuario("user1")
      otro = crear_usuario("user2")
      m = crear_moneda("USD")

      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => otro.id, "moneda_origen_id" => m.id, "monto" => 0.1, "tipo" => "alta_cuenta"})

      {:ok, tx} = TransaccionesDB.realizar_transferencia(%{"cuenta_origen_id" => u.id, "cuenta_destino_id" => otro.id, "moneda_id" => m.id, "monto" => 4.0})

      output = capture_io(fn ->
        Ledger.CLI.main(["ver_transaccion", "-id=#{tx.id}"])
      end)

      assert output =~ "Transacción ##{tx.id}" or output =~ "Usuario origen"
    end

    # tests de validación de flags
    test "alta_cuenta CLI sin flags obligatorios" do
      output = capture_io(fn ->
        Ledger.CLI.main(["alta_cuenta"])
      end)
      assert output =~ "Falta el flag" or output =~ "Monto invalido"
    end

    test "realizar_transferencia CLI con monto inválido" do
      u1 = crear_usuario("userA")
      u2 = crear_usuario("userB")
      m = crear_moneda("USD")
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u1.id, "moneda_origen_id" => m.id, "monto" => 10.0, "tipo" => "alta_cuenta"})
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u2.id, "moneda_origen_id" => m.id, "monto" => 10.0, "tipo" => "alta_cuenta"})

      output = capture_io(fn ->
        Ledger.CLI.main(["realizar_transferencia", "-o=#{u1.id}", "-d=#{u2.id}", "-m=#{m.id}", "-a=notanumber"])
      end)
      assert output =~ "Monto invalido" or output =~ "Falta el flag"
    end

    test "realizar_swap CLI con monto inválido" do
      u = crear_usuario("userC")
      m1 = crear_moneda("USD")
      m2 = crear_moneda("BTC")
      assert {:ok, _} = TransaccionesDB.alta_cuenta(%{"cuenta_origen_id" => u.id, "moneda_origen_id" => m1.id, "monto" => 1.0, "tipo" => "alta_cuenta"})

      output = capture_io(fn ->
        Ledger.CLI.main(["realizar_swap", "-u=#{u.id}", "-mo=#{m1.id}", "-md=#{m2.id}", "-a=abc"])
      end)
      assert output =~ "Monto invalido" or output =~ "Falta el flag"
    end

    test "deshacer_transaccion CLI con ID no numérico" do
      output = capture_io(fn ->
        Ledger.CLI.main(["deshacer_transaccion", "-id=abc"])
      end)
      assert output =~ "argumento inválido" or output =~ "error"
    end

    test "ver_transaccion CLI con ID no numérico" do
      output = capture_io(fn ->
        Ledger.CLI.main(["ver_transaccion", "-id=xyz"])
      end)
      assert output =~ "ID inválido"
    end

    test "realizar_transferencia CLI sin flags obligatorios" do
      output = capture_io(fn ->
        Ledger.CLI.main(["realizar_transferencia"])
      end)
      assert output =~ "Falta el flag" or output =~ "Monto invalido"
    end

    test "realizar_swap CLI sin flags obligatorios" do
      output = capture_io(fn ->
        Ledger.CLI.main(["realizar_swap"])
      end)
      assert output =~ "Falta el flag" or output =~ "Monto invalido"
    end
  end


end
