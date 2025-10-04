defmodule Ledger.Usuarios.Usuario do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields [:nombre_usuario, :fecha_nacimiento]

  schema "usuarios" do
    field :nombre_usuario, :string
    field :fecha_nacimiento, :date

    timestamps(inserted_at: :fecha_creacion, updated_at: :updated_at)
  end

  def changeset_crear(usuario, attrs) do
    usuario
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validar_mayor_de_18(:fecha_nacimiento)
    |> unique_constraint(:nombre_usuario)
  end

  def changeset_editar(%__MODULE__{} = usuario, attrs) do
    usuario
    |> cast(attrs, [:nombre_usuario])
    |> validar_nombre_distinto()
    |> unique_constraint(:nombre_usuario)
  end

  defp validar_mayor_de_18(changeset, field) do
    case get_field(changeset, field) do
      %Date{} = fecha_nac ->
        if edad(fecha_nac) >= 18 do
          changeset
        else
          add_error(changeset, field, "el usuario debe tener al menos 18 años")
        end
      _ -> changeset
    end
  end

  defp edad(%Date{year: y, month: m, day: d}) do
    hoy = Date.utc_today()
    años = hoy.year - y
    if (hoy.month < m) or (hoy.month == m and hoy.day < d), do: años - 1, else: años
  end

  defp validar_nombre_distinto(changeset) do
    anterior = changeset.data.nombre_usuario
    case get_change(changeset, :nombre_usuario) do
      nil -> changeset
      ^anterior -> add_error(changeset, :nombre_usuario, "el nombre de usuario debe ser distinto al anterior")
      _ -> changeset
    end
  end
end
