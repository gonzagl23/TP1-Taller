defmodule Ledger.CLI do
  def main(argv) do
    case argv do
      ["transacciones" | flags] ->
        Ledger.Transacciones.listar(flags)

      ["balance" | flags] ->
        Ledger.Balance.calcular(flags)

      ["crear_usuario" | flags] ->
        Ledger.UsuariosCLI.crear(flags)

      ["editar_usuario" | flags] ->
        Ledger.UsuariosCLI.editar(flags)

      ["borrar_usuario" | flags] ->
        Ledger.UsuariosCLI.borrar(flags)

      ["ver_usuario" | flags] ->
        Ledger.UsuariosCLI.ver(flags)

      ["crear_moneda" | flags] ->
        Ledger.MonedasCLI.crear(flags)

      ["editar_moneda" | flags] ->
        Ledger.MonedasCLI.editar(flags)

      ["borrar_moneda" | flags] ->
        Ledger.MonedasCLI.borrar(flags)

      ["ver_moneda" | flags] ->
        Ledger.MonedasCLI.ver(flags)

      ["alta_cuenta" | flags] ->
        Ledger.TransaccionesCLI.alta_cuenta(flags)

      ["realizar_transferencia" | flags] ->
        Ledger.TransaccionesCLI.realizar_transferencia(flags)

      ["realizar_swap" | flags] ->
        Ledger.TransaccionesCLI.realizar_swap(flags)

      ["deshacer_transaccion" | flags] ->
        Ledger.TransaccionesCLI.deshacer_transaccion(flags)

      ["ver_transaccion" | flags] ->
        Ledger.TransaccionesCLI.ver_transaccion(flags)

      _caso_incorrecto ->
        IO.puts("Uso: ./ledger [Funcion] [flags]")
    end
  end
end
