defmodule Ledger.Monedas.Moneda do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields [:nombre_moneda, :precio_dolares]

  schema "monedas" do
    field :nombre_moneda, :string
    field :precio_dolares, :float

    timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion)
  end

  def changeset_crear(moneda, attrs) do
    moneda
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validar_nombre_mayusculas_y_longitud(:nombre_moneda)
    |> validate_number(:precio_dolares, greater_than_por_equal_to: 0)
    |> unique_constraint(:nombre_moneda)
  end

  def changeset_editar(moneda, attrs) do
    moneda
    |> cast(attrs, [:precio_dolares])
    |> validate_required([:precio_dolares])
    |> validate_number(:precio_dolares, greater_than_or_equal_to: 0)
  end

  defp validar_nombre_mayusculas_y_longitud(changeset, field) do
    changeset
    |> validate_format(field, ~r/^[A-Z]{3,4}$/, message: "debe estar en mayúsculas y tener entre 3 y 4 letras")
  end

end
