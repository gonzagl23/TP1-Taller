defmodule Ledger.CSVParser do
  @moduledoc """
  Funciones para leer y parsear archivos CSV.
  """

  def leer_transacciones(ruta) do
    File.stream!(ruta)
    |> Enum.with_index(1)
    |> Enum.map(fn {linea, nro_linea} -> parse_transaccion(String.trim(linea), nro_linea) end)
  end

  defp parse_transaccion(linea, nro_linea) do
    case String.split(linea, ";") do
      [id, fh, m_origen, m_destino, monto_str, c_origen, c_destino, tipo] ->
        case Float.parse(monto_str) do
          {monto, ""} ->
            {:ok,
            %{
              id: id,
              fecha_hora: fh,
              moneda_origen: m_origen,
              moneda_destino: m_destino,
              monto: monto,
              cuenta_origen: c_origen,
              cuenta_destino: c_destino,
              tipo: tipo
            }}

          :error ->
            {:error, nro_linea}
        end

      _error ->
        {:error, nro_linea}
    end
  end


  def leer_monedas(ruta) do
  File.stream!(ruta)
  |> Enum.map(fn linea ->
    [moneda, precio_str] = String.split(String.trim(linea), ";")

    case Float.parse(precio_str) do
      {precio, ""} -> {moneda, precio}
      :error -> raise "Precio inválido en moneda #{moneda}: #{precio_str}"
    end
  end)
  |> Enum.into(%{})
end


end
