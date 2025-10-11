defmodule Ledger.UsuariosTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Ledger.Repo
  alias Ledger.Usuarios

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "crear_usuario" do
    test "crea un usuario válido" do
      attrs = %{"nombre_usuario" => "Ana", "fecha_nacimiento" => ~D[1990-01-01]}
      {:ok, usuario} = Usuarios.crear_usuario(attrs)
      assert usuario.nombre_usuario == "Ana"
    end

    test "permite usuario con exactamente 18 años" do
      hoy = Date.utc_today()
      fecha_18 =
        case Date.new(hoy.year - 18, hoy.month, hoy.day) do
          {:ok, d} -> d
          _ -> Date.add(hoy, -365 * 18) |> Date.add(0)
        end

      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Lolo", "fecha_nacimiento" => fecha_18})
      assert usuario.nombre_usuario == "Lolo"
    end

    test "no crea usuario menor de 18 años" do
      attrs = %{"nombre_usuario" => "Pepe", "fecha_nacimiento" => Date.utc_today()}
      {:error, changeset} = Usuarios.crear_usuario(attrs)
      assert Enum.any?(changeset.errors, fn
        {:fecha_nacimiento, {"el usuario debe tener al menos 18 años", _}} -> true
        _ -> false
      end)
    end

    test "no crea usuario sin nombre" do
      attrs = %{"fecha_nacimiento" => ~D[1990-01-01]}
      {:error, changeset} = Usuarios.crear_usuario(attrs)
      assert Enum.any?(changeset.errors, fn
        {:nombre_usuario, {"can't be blank", _}} -> true
        _ -> false
      end)
    end

    test "no crea usuario sin fecha de nacimiento" do
      attrs = %{"nombre_usuario" => "Ana"}
      {:error, changeset} = Usuarios.crear_usuario(attrs)
      assert Enum.any?(changeset.errors, fn
        {:fecha_nacimiento, {"can't be blank", _}} -> true
        _ -> false
      end)
    end

    test "no crea cuando fecha es string inválido" do
      {:error, changeset} = Usuarios.crear_usuario(%{"nombre_usuario" => "Zalo", "fecha_nacimiento" => "hola"})
      assert changeset.valid? == false
    end

    test "no crea cuando fecha es nil explícito" do
      {:error, changeset} = Usuarios.crear_usuario(%{"nombre_usuario" => "Gonza", "fecha_nacimiento" => nil})
      assert Enum.any?(changeset.errors, fn {campo, _} -> campo == :fecha_nacimiento end)
    end

    test "no permite crear usuario con nombre duplicado" do
      {:ok, _u1} = Usuarios.crear_usuario(%{"nombre_usuario" => "Luis", "fecha_nacimiento" => ~D[1990-01-01]})
      {:error, changeset} = Usuarios.crear_usuario(%{"nombre_usuario" => "Luis", "fecha_nacimiento" => ~D[1990-01-01]})
      assert Enum.any?(changeset.errors, fn
        {:nombre_usuario, {"has already been taken", _}} -> true
        _ -> false
      end)
    end
  end

  describe "ver_usuario" do
    test "devuelve usuario existente" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Juan", "fecha_nacimiento" => ~D[1995-05-05]})
      {:ok, encontrado} = Usuarios.ver_usuario(usuario.id)
      assert encontrado.id == usuario.id
    end

    test "error si usuario no existe" do
      assert {:error, :ver_usuario, _} = Usuarios.ver_usuario(999)
    end
  end

  describe "editar_usuario" do
    test "edita nombre correctamente" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Luis", "fecha_nacimiento" => ~D[1990-01-01]})
      {:ok, editado} = Usuarios.editar_usuario(usuario, %{nombre_usuario: "Luisito"})
      assert editado.nombre_usuario == "Luisito"
    end

    test "editar con attrs vacíos no provoca error y no cambia nombre" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Nico", "fecha_nacimiento" => ~D[1990-01-01]})
      {:ok, u2} = Usuarios.editar_usuario(usuario, %{})
      assert u2.id == usuario.id
      assert u2.nombre_usuario == "Nico"
    end

    test "no permite cambiar al mismo nombre" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Marta", "fecha_nacimiento" => ~D[1990-01-01]})
      {:error, changeset} = Usuarios.editar_usuario(usuario, %{nombre_usuario: "Marta"})
      assert Enum.any?(changeset.errors, fn
        {:nombre_usuario, {"el nombre de usuario debe ser distinto al anterior", _}} -> true
        _ -> false
      end)
    end
  end

  describe "borrar_usuario" do
    test "borra usuario sin transacciones" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Carlos", "fecha_nacimiento" => ~D[1990-01-01]})
      {:ok, _} = Usuarios.borrar_usuario(usuario)
      assert {:error, :ver_usuario, _} = Usuarios.ver_usuario(usuario.id)
    end
  end

  describe "UsuariosCLI" do
    test "crear con usuario válido" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["crear_usuario", "-n=Pedro", "-b=1990-05-05"])
        end)

      assert output =~ "Pedro"
      assert output =~ "1990-05-05"
    end

    test "crear con fecha inválida" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["crear_usuario", "-n=Pedro", "-b=2025-01-01"])
        end)

      assert output =~ "Fecha invalida" or output =~ "el usuario debe tener al menos 18 años"
    end

    test "crear sin nombre muestra mensaje de falta de flag" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["crear_usuario", "-b=1990-01-01"])
        end)

      assert output =~ "Falta" or output =~ "nombre"
    end

    test "editar con nombre válido" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Ana", "fecha_nacimiento" => ~D[1990-01-01]})

      output =
        capture_io(fn ->
          Ledger.CLI.main(["editar_usuario", "-id=#{usuario.id}", "-n=Anita"])
        end)

      assert output =~ "Usuario editado correctamente"
      assert output =~ "Anita"
    end

    test "editar con mismo nombre" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Luis", "fecha_nacimiento" => ~D[1990-01-01]})

      output =
        capture_io(fn ->
          Ledger.CLI.main(["editar_usuario", "-id=#{usuario.id}", "-n=Luis"])
        end)

      assert output =~ "El nombre de usuario debe ser distinto al anterior"
    end

    test "editar con id inválido muestra ID invalido" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["editar_usuario", "-id=abc", "-n=Hola"])
        end)

      assert output =~ "ID invalido" or output =~ "Falta"
    end

    test "editar usuario inexistente informa no existe" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["editar_usuario", "-id=999999", "-n=Paloma"])
        end)

      assert output =~ "no existe" or output =~ "No se puede"
    end

    test "borrar usuario existente" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Marta", "fecha_nacimiento" => ~D[1990-01-01]})

      output =
        capture_io(fn ->
          Ledger.CLI.main(["borrar_usuario", "-id=#{usuario.id}"])
        end)

      assert output =~ "Usuario borrado correctamente"
    end

    test "borrar usuario inexistente" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["borrar_usuario", "-id=999"])
        end)

      assert output =~ "No se puede borrar el usuario"
    end

    test "borrar con id inválido muestra ID invalido" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["borrar_usuario", "-id=Hola"])
        end)

      assert output =~ "ID invalido" or output =~ "Falta"
    end

    test "ver usuario existente" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Juan", "fecha_nacimiento" => ~D[1990-01-01]})

      output =
        capture_io(fn ->
          Ledger.CLI.main(["ver_usuario", "-id=#{usuario.id}"])
        end)

      assert output =~ "Juan"
    end

    test "ver usuario inexistente" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["ver_usuario", "-id=999"])
        end)

      assert output =~ "Error"
    end

    test "ver con id inválido muestra ID invalido" do
      output =
        capture_io(fn ->
          Ledger.CLI.main(["ver_usuario", "-id=Hola"])
        end)

      assert output =~ "ID invalido" or output =~ "Falta"
    end
  end
end
