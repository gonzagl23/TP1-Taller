defmodule Ledger.UsuariosTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Ledger.Repo
  alias Ledger.Usuarios
  alias Ledger.UsuariosCLI

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "crear_usuario/1" do
    test "crea un usuario válido" do
      attrs = %{"nombre_usuario" => "Ana", "fecha_nacimiento" => ~D[1990-01-01]}
      {:ok, usuario} = Usuarios.crear_usuario(attrs)
      assert usuario.nombre_usuario == "Ana"
    end

    test "no crea usuario menor de 18 años" do
      attrs = %{"nombre_usuario" => "Pepe", "fecha_nacimiento" => Date.utc_today()}
      {:error, changeset} = Usuarios.crear_usuario(attrs)
      assert {"el usuario debe tener al menos 18 años", _} = changeset.errors[:fecha_nacimiento]
    end
  end

  describe "ver_usuario/1" do
    test "devuelve usuario existente" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Juan", "fecha_nacimiento" => ~D[1995-05-05]})
      {:ok, encontrado} = Usuarios.ver_usuario(usuario.id)
      assert encontrado.id == usuario.id
    end

    test "error si usuario no existe" do
      assert {:error, :ver_usuario, _} = Usuarios.ver_usuario(4)
    end
  end

  describe "editar_usuario/2" do
    test "edita nombre correctamente" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Luis", "fecha_nacimiento" => ~D[1990-01-01]})
      {:ok, editado} = Usuarios.editar_usuario(usuario, %{nombre_usuario: "Luisito"})
      assert editado.nombre_usuario == "Luisito"
    end

    test "no permite cambiar al mismo nombre" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Marta", "fecha_nacimiento" => ~D[1990-01-01]})
      {:error, changeset} = Usuarios.editar_usuario(usuario, %{nombre_usuario: "Marta"})
      assert {"el nombre de usuario debe ser distinto al anterior", _} = changeset.errors[:nombre_usuario]
    end
  end

  describe "borrar_usuario/1" do
    test "borra usuario sin transacciones" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Carlos", "fecha_nacimiento" => ~D[1990-01-01]})
      {:ok, _} = Usuarios.borrar_usuario(usuario)
      assert {:error, :ver_usuario, _} = Usuarios.ver_usuario(usuario.id)
    end
  end


  describe "UsuariosCLI" do
    test "crear CLI con usuario válido" do
      output =
        capture_io(fn ->
          UsuariosCLI.crear(["-n=Pedro", "-b=1990-05-05"])
        end)

      assert output =~ "Pedro"
      assert output =~ "1990-05-05"
    end

    test "crear CLI con fecha inválida" do
      output =
        capture_io(fn ->
          UsuariosCLI.crear(["-n=Pedro", "-b=2025-01-01"])
        end)

      assert output =~ "Fecha invalida" or output =~ "el usuario debe tener al menos 18 años"
    end

    test "editar CLI con nombre válido" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Ana", "fecha_nacimiento" => ~D[1990-01-01]})

      output =
        capture_io(fn ->
          UsuariosCLI.editar(["-id=#{usuario.id}", "-n=Anita"])
        end)

      assert output =~ "Usuario editado correctamente"
      assert output =~ "Anita"
    end

    test "editar CLI con mismo nombre" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Luis", "fecha_nacimiento" => ~D[1990-01-01]})

      output =
        capture_io(fn ->
          UsuariosCLI.editar(["-id=#{usuario.id}", "-n=Luis"])
        end)

      assert output =~ "El nombre de usuario debe ser distinto al anterior"
    end

    test "borrar CLI usuario existente" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Marta", "fecha_nacimiento" => ~D[1990-01-01]})

      output =
        capture_io(fn ->
          UsuariosCLI.borrar(["-id=#{usuario.id}"])
        end)

      assert output =~ "Usuario borrado correctamente"
    end

    test "borrar CLI usuario inexistente" do
      output =
        capture_io(fn ->
          UsuariosCLI.borrar(["-id=999"])
        end)

      assert output =~ "No se puede borrar el usuario"
    end

    test "ver CLI usuario existente" do
      {:ok, usuario} = Usuarios.crear_usuario(%{"nombre_usuario" => "Juan", "fecha_nacimiento" => ~D[1990-01-01]})

      output =
        capture_io(fn ->
          UsuariosCLI.ver(["-id=#{usuario.id}"])
        end)

      assert output =~ "Juan"
    end

    test "ver CLI usuario inexistente" do
      output =
        capture_io(fn ->
          UsuariosCLI.ver(["-id=999"])
        end)

      assert output =~ "Error"
    end
  end
end
