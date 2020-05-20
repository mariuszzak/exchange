defmodule ExchangeTest do
  @moduledoc false
  use ExUnit.Case

  describe "start_link/0" do
    test "it returns a pid of a server when successfully started" do
      assert {:ok, pid} = Exchange.start_link()
      assert is_pid(pid)
    end

    test "it retruns an error when a server is already started" do
      assert {:ok, pid} = Exchange.start_link()
      assert {:error, {:already_started, ^pid}} = Exchange.start_link()
    end
  end
end
