defmodule Ledger.CLI do
  def main(argv) do
    case argv do
      ["transacciones" | rest] ->
        Ledger.Transacciones.listar(rest)

      ["balance" | rest] ->
        Ledger.Balance.calcular(rest)

      _caso_incorrecto ->
        IO.puts("Uso: ./ledger [transacciones|balance] [flags]")
    end
  end
end
