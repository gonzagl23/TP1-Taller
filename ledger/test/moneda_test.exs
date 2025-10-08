defmodule Ledger.MonedasTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Ledger.Monedas
  alias Ledger.Monedas.Moneda
  alias Ledger.Repo
  alias Ledger.MonedasCLI

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "crear_moneda/1" do
    test "crea moneda válida" do
      attrs = %{"nombre_moneda" => "BTC", "precio_dolares" => 3000.00}
      assert {:ok, %Moneda{} = moneda} = Monedas.crear_moneda(attrs)
      assert moneda.nombre_moneda == "BTC"
      assert moneda.precio_dolares == 3000.00
    end

    test "nombre inválido (minúsculas o longitud incorrecta)" do
      attrs = %{"nombre_moneda" => "bt", "precio_dolares" => 1000.00}
      assert {:error, changeset} = Monedas.crear_moneda(attrs)
      assert Keyword.has_key?(changeset.errors, :nombre_moneda)
    end

    test "precio negativo" do
      attrs = %{"nombre_moneda" => "ETH", "precio_dolares" => -10.00}
      assert {:error, changeset} = Monedas.crear_moneda(attrs)
      assert Keyword.has_key?(changeset.errors, :precio_dolares)
    end

    test "nombre duplicado" do
      attrs = %{"nombre_moneda" => "XRP", "precio_dolares" => 1.0}
      {:ok, _} = Monedas.crear_moneda(attrs)
      assert {:error, changeset} = Monedas.crear_moneda(attrs)
      assert Keyword.has_key?(changeset.errors, :nombre_moneda)
    end
  end

  describe "ver_moneda/1" do
    test "devuelve moneda existente" do
      {:ok, moneda} = Monedas.crear_moneda(%{"nombre_moneda" => "LTC", "precio_dolares" => 80.00})
      assert {:ok, ^moneda} = Monedas.ver_moneda(moneda.id)
    end

    test "error si no existe" do
      assert {:error, :ver_moneda, _msg} = Monedas.ver_moneda(10)
    end
  end

  describe "editar_moneda/2" do
    test "cambia precio correctamente" do
      {:ok, moneda} = Monedas.crear_moneda(%{"nombre_moneda" => "DOGE", "precio_dolares" => 0.10})
      assert {:ok, moneda_editada} = Monedas.editar_moneda(moneda, %{precio_dolares: 0.15})
      assert moneda_editada.precio_dolares == 0.15
    end

    test "error con precio negativo" do
      {:ok, moneda} = Monedas.crear_moneda(%{"nombre_moneda" => "ADA", "precio_dolares" => 1.2})
      assert {:error, changeset} = Monedas.editar_moneda(moneda, %{precio_dolares: -1.0})
      assert Keyword.has_key?(changeset.errors, :precio_dolares)
    end
  end

  describe "borrar_moneda/1" do
    test "borra moneda sin transacciones" do
      {:ok, moneda} = Monedas.crear_moneda(%{"nombre_moneda" => "BNB", "precio_dolares" => 200.00})
      assert {:ok, _} = Monedas.borrar_moneda(moneda)
      assert {:error, :ver_moneda, _} = Monedas.ver_moneda(moneda.id)
    end
  end

  describe "MonedasCLI" do
    test "crear CLI exitosa" do
      output =
        capture_io(fn ->
          MonedasCLI.crear(["-n=EOS", "-p=5.0"])
        end)

      assert output =~ "EOS"
      assert output =~ "5.0"
    end

    test "crear CLI precio faltante" do
      output =
        capture_io(fn ->
          MonedasCLI.crear(["-n=EOS"])
        end)

      assert output =~ "Falta el flag -p"
    end

    test "crear CLI precio inválido" do
      output =
        capture_io(fn ->
          MonedasCLI.crear(["-n=EOS", "-p=abc"])
        end)

      assert output =~ "Precio invalido"
    end

    test "editar CLI sin cambios" do
      {:ok, moneda} = Monedas.crear_moneda(%{"nombre_moneda" => "TRX", "precio_dolares" => 1.0})

      output =
        capture_io(fn ->
          MonedasCLI.editar(["-id=#{moneda.id}"])
        end)

      assert output =~ "No hay cambios para aplicar"
    end

    test "editar CLI con precio válido" do
      {:ok, moneda} = Monedas.crear_moneda(%{"nombre_moneda" => "TRX", "precio_dolares" => 1.0})

      output =
        capture_io(fn ->
          MonedasCLI.editar(["-id=#{moneda.id}", "-p=2.0"])
        end)

      assert output =~ "Moneda editada correctamente"
      assert output =~ "2.0"
    end

    test "editar CLI moneda inexistente" do
      output =
        capture_io(fn ->
          MonedasCLI.editar(["-id=999", "-p=2.0"])
        end)

      assert output =~ "no existe" || output =~ "La moneda no existe"
    end

    test "borrar CLI exitosa" do
      {:ok, moneda} = Monedas.crear_moneda(%{"nombre_moneda" => "SOL", "precio_dolares" => 20.0})

      output =
        capture_io(fn ->
          MonedasCLI.borrar(["-id=#{moneda.id}"])
        end)

      assert output =~ "Moneda borrada correctamente"
    end

    test "ver CLI existente" do
      {:ok, moneda} = Monedas.crear_moneda(%{"nombre_moneda" => "LINK", "precio_dolares" => 7.0})

      output =
        capture_io(fn ->
          MonedasCLI.ver(["-id=#{moneda.id}"])
        end)

      assert output =~ "LINK"
      assert output =~ "7.0"
    end

    test "ver CLI moneda inexistente" do
      output =
        capture_io(fn ->
          MonedasCLI.ver(["-id=999"])
        end)

      assert output =~ "no existe" || output =~ "La moneda no existe"
    end
  end
end
