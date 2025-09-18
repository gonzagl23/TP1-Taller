defmodule Ledger.CLI do
  def main(argv) do
    case argv do
      ["transacciones" | flags] ->
        Ledger.Transacciones.listar(flags)

      ["balance" | flags] ->
        Ledger.Balance.calcular(flags)

      _caso_incorrecto ->
        IO.puts("Uso: ./ledger [transacciones|balance] [flags]")
    end
  end
end
