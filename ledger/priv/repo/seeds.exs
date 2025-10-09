alias Ledger.Repo
alias Ledger.Usuarios.Usuario
alias Ledger.Monedas.Moneda
alias Ledger.TransaccionesDB.Transaccion

IO.puts("Creando usuarios...")

{:ok, u1} =
  %Usuario{
    nombre_usuario: "Gonza",
    fecha_nacimiento: ~D[1995-04-21]
  }
  |> Repo.insert()

{:ok, u2} =
  %Usuario{
    nombre_usuario: "Pepe",
    fecha_nacimiento: ~D[1990-11-02]
  }
  |> Repo.insert()

{:ok, u3} =
  %Usuario{
    nombre_usuario: "Lolo",
    fecha_nacimiento: ~D[2001-06-15]
  }
  |> Repo.insert()

IO.puts("Creando monedas...")

{:ok, m1} =
  %Moneda{
    nombre_moneda: "USD",
    precio_dolares: 100.00
  }
  |> Repo.insert()

{:ok, m2} =
  %Moneda{
    nombre_moneda: "ARS",
    precio_dolares: 1000.00
  }
  |> Repo.insert()

{:ok, m3} =
  %Moneda{
    nombre_moneda: "EUR",
    precio_dolares: 500.00
  }
  |> Repo.insert()

IO.puts("Creando transacciones...")

{:ok, _t1} =
  %Transaccion{
    timestamp: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    moneda_origen_id: m1.id,
    cuenta_origen_id: u1.id,
    monto: 1000.00,
    tipo: "alta_cuenta"
  }
  |> Repo.insert()

{:ok, _t2} =
  %Transaccion{
    timestamp: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    moneda_origen_id: m1.id,
    cuenta_origen_id: u2.id,
    monto: 5000.00,
    tipo: "alta_cuenta"
  }
  |> Repo.insert()


{:ok, _t3} =
  %Transaccion{
    timestamp: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    cuenta_origen_id: u1.id,
    moneda_origen_id: m1.id,
    moneda_destino_id: m2.id,
    monto: 100.00,
    tipo: "swap"
  }
  |> Repo.insert()

{:ok, _t4} =
  %Transaccion{
    timestamp: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    moneda_origen_id: m1.id,
    cuenta_origen_id: u3.id,
    monto: 500.00,
    tipo: "alta_cuenta"
  }
  |> Repo.insert()

{:ok, _t5} =
  %Transaccion{
    timestamp: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    cuenta_origen_id: u3.id,
    moneda_origen_id: m1.id,
    moneda_destino_id: m3.id,
    monto: 100.00,
    tipo: "swap"
  }
  |> Repo.insert()

{:ok, _t6} =
  %Transaccion{
    timestamp: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    cuenta_origen_id: u1.id,
    cuenta_destino_id: u2.id,
    moneda_origen_id: m1.id,
    monto: 10.00,
    tipo: "transferencia"
  }
  |> Repo.insert()

{:ok, _t7} =
  %Transaccion{
    timestamp: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    cuenta_origen_id: u2.id,
    cuenta_destino_id: u1.id,
    moneda_origen_id: m1.id,
    monto: 10.00,
    tipo: "deshacer"
  }
  |> Repo.insert()



IO.puts("Datos iniciales cargados correctamente ✅")
