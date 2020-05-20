defmodule ExchangeTest do
  @moduledoc false
  use ExUnit.Case

  describe "start_link/0" do
    test "it returns a pid of a server when successfully started" do
      assert {:ok, pid} = Exchange.start_link()
      assert is_pid(pid)
    end

    test "it allows to run multiple servers" do
      assert {:ok, pid1} = Exchange.start_link()
      assert {:ok, pid2} = Exchange.start_link()
      assert pid1 != pid2
    end
  end
end
