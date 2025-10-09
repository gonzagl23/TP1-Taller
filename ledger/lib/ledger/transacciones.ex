defmodule Ledger.Transacciones do
  @moduledoc """
  Funcionalidad para listar transacciones.
  """

  import Ecto.Query, only: [from: 2]
  alias Ledger.Repo
  alias Ledger.TransaccionesDB.Transaccion
  alias Ledger.CSVParser

  # Listar transacciones con flags y opciones
  def listar(flags, _opts \\ []) do
    opciones = parsear_flags(flags)
    archivo_transacciones = Map.get(opciones, :archivo)
    cuenta_origen = Map.get(opciones, :cuenta_origen)
    cuenta_destino = Map.get(opciones, :cuenta_destino)
    archivo_salida = Map.get(opciones, :archivo_salida)

    usar_csv = not is_nil(archivo_transacciones)

    transacciones =
      if usar_csv do
        CSVParser.leer_transacciones(archivo_transacciones)
      else
        obtener_transacciones_db()
      end

    opts_validacion = [usar_csv: usar_csv]

    case validar_y_filtrar(transacciones, cuenta_origen, cuenta_destino, opts_validacion) do
      {:error, errores} ->
        Enum.each(errores, &IO.puts/1)
        exit(:error)

      {:ok, transacciones_validas, _cuentas_activas} ->
        if transacciones_validas == [] do
          IO.puts("Error: No se encontraron transacciones que coincidan con los filtros")
          exit(:error)
        end

        if archivo_salida do
          guardar_transacciones_csv(transacciones_validas, archivo_salida)
        else
          mostrar_transacciones_por_pantalla(transacciones_validas)
        end
    end
  end

  # Obtener transacciones desde la DB
  def obtener_transacciones_db do
    Repo.all(
      from(t in Transaccion,
        order_by: [asc: t.fecha_creacion, asc: t.id],
        preload: [:moneda_origen, :moneda_destino, :cuenta_origen, :cuenta_destino]
      )
    )
    |> Enum.map(fn t ->
      moneda_origen = if t.moneda_origen, do: String.trim(t.moneda_origen.nombre_moneda), else: ""
      moneda_destino = if t.moneda_destino, do: String.trim(t.moneda_destino.nombre_moneda), else: ""
      cuenta_origen = if t.cuenta_origen, do: Integer.to_string(t.cuenta_origen.id), else: ""
      cuenta_destino = if t.cuenta_destino, do: Integer.to_string(t.cuenta_destino.id), else: ""

      {:ok,
       %{
         id: t.id,
         fecha_hora: NaiveDateTime.to_string(t.fecha_creacion),
         moneda_origen: moneda_origen,
         moneda_destino: moneda_destino,
         monto: t.monto,
         cuenta_origen: cuenta_origen,
         cuenta_destino: cuenta_destino,
         tipo: t.tipo
       }}
    end)
  end

  # Validar transacciones y aplicar filtros
  def validar_y_filtrar(transacciones, cuenta_origen \\ nil, cuenta_destino \\ nil, opts \\ []) do
    cuentas_activas =
      Enum.reduce(transacciones, MapSet.new(), fn
        {:ok, t}, acc when t.tipo == "alta_cuenta" -> MapSet.put(acc, t.cuenta_origen)
        _transaccion, acc -> acc
      end)

    # Construimos el mapa de monedas: CSV o DB
    monedas =
      if opts[:usar_csv] do
        CSVParser.leer_monedas("monedas.csv")
      else
        Repo.all(Ledger.Monedas.Moneda)
        |> Enum.reduce(%{}, fn m, acc -> Map.put(acc, String.trim(m.nombre_moneda), m.precio_dolares) end)
      end

    {errores, validas} =
      Enum.reduce(transacciones, {[], []}, fn
        {:error, numero_linea}, {errs, oks} ->
          {["Error de formato en línea #{numero_linea}" | errs], oks}

        {:ok, transaccion}, {errs, oks} ->
          case validar_transaccion(transaccion, cuentas_activas, monedas) do
            :ok ->
              if aplicar_filtro_transaccion?(transaccion, cuenta_origen, cuenta_destino) do
                {errs, [transaccion | oks]}
              else
                {errs, oks}
              end

            {:error, id_transaccion, mensaje_error} ->
              {["Error en transaccion #{id_transaccion}: #{mensaje_error}" | errs], oks}
          end
      end)

    if errores == [], do: {:ok, Enum.reverse(validas), cuentas_activas}, else: {:error, Enum.reverse(errores)}
  end

  # Validar transacción individual
  defp validar_transaccion(transaccion, cuentas_activas, monedas) do
    tipos_validos = ["transferencia", "swap", "alta_cuenta", "deshacer"]

    with true <-
           transaccion.tipo in tipos_validos ||
             {:error, transaccion.id, "Tipo de transaccion inválido: #{transaccion.tipo}"},
         true <-
           transaccion.monto > 0 ||
             {:error, transaccion.id, "Monto negativo o cero"},
         true <-
           Map.has_key?(monedas, transaccion.moneda_origen) ||
             {:error, transaccion.id, "Moneda de origen inválida: #{transaccion.moneda_origen}"},
         true <-
           transaccion.moneda_destino == "" or Map.has_key?(monedas, transaccion.moneda_destino) ||
             {:error, transaccion.id, "Moneda de destino inválida: #{transaccion.moneda_destino}"},
         true <-
           transaccion.tipo not in ["transferencia", "deshacer"] or
             (transaccion.cuenta_origen != "" and transaccion.cuenta_destino != "") ||
             {:error, transaccion.id, "Transferencia/deshacer debe tener cuenta_origen y cuenta_destino"},
         true <-
           transaccion.tipo != "swap" or
             (transaccion.cuenta_origen != "" and transaccion.moneda_destino != "") ||
             {:error, transaccion.id, "Swap debe tener cuenta_origen y moneda_destino"},
         true <-
           transaccion.tipo != "alta_cuenta" or
             (transaccion.cuenta_origen != "" and transaccion.monto > 0) ||
             {:error, transaccion.id, "Alta_cuenta debe tener cuenta_origen y monto positivo"},
         true <-
           transaccion.tipo not in ["transferencia", "deshacer"] or
             (MapSet.member?(cuentas_activas, transaccion.cuenta_origen) and
                MapSet.member?(cuentas_activas, transaccion.cuenta_destino)) ||
             {:error, transaccion.id, "Cuenta no dada de alta en transferencia/deshacer"},
         true <-
           transaccion.tipo != "swap" or
             MapSet.member?(cuentas_activas, transaccion.cuenta_origen) ||
             {:error, transaccion.id, "Cuenta no dada de alta en swap"} do
      :ok
    end
  end

  # Filtro por cuenta origen/destino
  defp aplicar_filtro_transaccion?(transaccion, cuenta_origen, cuenta_destino) do
    (is_nil(cuenta_origen) or transaccion.cuenta_origen == cuenta_origen) and
      (is_nil(cuenta_destino) or transaccion.cuenta_destino == cuenta_destino)
  end

  # Mostrar transacciones por pantalla
  defp mostrar_transacciones_por_pantalla(transacciones) do
    Enum.each(transacciones, fn transaccion ->
      monto_formateado = :erlang.float_to_binary(transaccion.monto, decimals: 6)

      IO.puts(
        "#{transaccion.id};#{transaccion.fecha_hora};#{transaccion.moneda_origen};#{transaccion.moneda_destino};#{monto_formateado};#{transaccion.cuenta_origen};#{transaccion.cuenta_destino};#{transaccion.tipo}"
      )
    end)
  end

  # Guardar transacciones en CSV
  defp guardar_transacciones_csv(transacciones, ruta_archivo) do
    File.open!(ruta_archivo, [:write], fn file ->
      Enum.each(transacciones, fn transaccion ->
        monto_str = :erlang.float_to_binary(transaccion.monto, decimals: 6)

        IO.write(
          file,
          "#{transaccion.id};#{transaccion.fecha_hora};#{transaccion.moneda_origen};#{transaccion.moneda_destino};#{monto_str};#{transaccion.cuenta_origen};#{transaccion.cuenta_destino};#{transaccion.tipo}\n"
        )
      end)
    end)
  end

  # Parsear flags CLI
  defp parsear_flags(args) do
    Enum.reduce(args, %{}, fn arg, acc ->
      case String.split(arg, "=") do
        ["-c1", valor] -> Map.put(acc, :cuenta_origen, valor)
        ["-c2", valor] -> Map.put(acc, :cuenta_destino, valor)
        ["-o", valor] -> Map.put(acc, :archivo_salida, valor)
        ["-t", valor] -> Map.put(acc, :archivo, valor)
        _ -> acc
      end
    end)
  end
end
