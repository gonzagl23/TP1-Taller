defmodule LedgerTest do
  use ExUnit.Case
  doctest Ledger

  test "greets the world" do
    assert Ledger.hello() == :world
  end
end
