defmodule ChecksumWeb.NumbersServerTest do
  alias Checksum.NumbersServer
  use ExUnit.Case

  setup do
    NumbersServer.clear()

    on_exit(fn ->
      NumbersServer.clear()
    end)
  end

  test "empty state yields checksum 0" do
    assert NumbersServer.checksum() == 0
  end

  test "adding number then clearing yields checksum 0" do
    NumbersServer.add("123")
    NumbersServer.clear()
    assert NumbersServer.checksum() == 0
  end

  test "adding 123 number yields checksum 6" do
    NumbersServer.add("123")
    assert NumbersServer.checksum() == 6
  end

  test "adding number starting with 0" do
    NumbersServer.add("0123")
    assert NumbersServer.checksum() == 0
  end

  test "adding numbers 1, 2 and 3 yields checksum 6" do
    Enum.each(["1", "2", "3"], &NumbersServer.add/1)
    assert NumbersServer.checksum() == 6
  end

  test "adding big number 5489850354 yields checksum 7" do
    NumbersServer.add("5489850354")
    assert NumbersServer.checksum() == 7
  end

  test "adding numbers 54 898 50 3 54 yields checksum 7" do
    Enum.each(["54", "898", "50", "3", "54"], &NumbersServer.add/1)
    assert NumbersServer.checksum() == 7
  end
end
