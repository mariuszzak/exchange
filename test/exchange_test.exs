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

  describe "send_instruction/2" do
    setup do
      {:ok, exchange_pid} = Exchange.start_link()
      [exchange_pid: exchange_pid]
    end

    test "it accepts an instruction of the 'new' type on the 'bid' side",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :new,
        side: :bid,
        price_level_index: 1,
        price: 50.0,
        quantity: 30
      }

      assert :ok = Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it accepts an instruction of the 'update' type on the 'bid' side",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :update,
        side: :bid,
        price_level_index: 1,
        price: 50.0,
        quantity: 30
      }

      assert :ok = Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it accepts an instruction of the 'delete' type on the 'bid' side",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :delete,
        side: :bid,
        price_level_index: 1,
        price: 50.0,
        quantity: 30
      }

      assert :ok = Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it returns error if instruction type is invalid on the 'bid' side",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :foo,
        side: :bid,
        price_level_index: 1,
        price: 50.0,
        quantity: 30
      }

      assert {:error, :invalid_instruction_type} =
               Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it accepts an instruction of the 'new' type on the 'ask' side",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :new,
        side: :ask,
        price_level_index: 1,
        price: 50.0,
        quantity: 30
      }

      assert :ok = Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it accepts an instruction of the 'update' type on the 'ask' side",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :update,
        side: :ask,
        price_level_index: 1,
        price: 50.0,
        quantity: 30
      }

      assert :ok = Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it accepts an instruction of the 'delete' type on the 'ask' side",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :delete,
        side: :ask,
        price_level_index: 1,
        price: 50.0,
        quantity: 30
      }

      assert :ok = Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it returns error if instruction type is invalid on the 'ask' side",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :foo,
        side: :ask,
        price_level_index: 1,
        price: 50.0,
        quantity: 30
      }

      assert {:error, :invalid_instruction_type} =
               Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it returns error if the 'side' param is invalid",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :delete,
        side: :foo,
        price_level_index: 1,
        price: 50.0,
        quantity: 30
      }

      assert {:error, :invalid_side_type} = Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it returns error if the 'price_level_index' param has invalid type",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :delete,
        side: :ask,
        price_level_index: :foo,
        price: 50.0,
        quantity: 30
      }

      assert {:error, :invalid_price_level_index_type} =
               Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it returns error if the 'price_level_index' param is lower than 1",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :delete,
        side: :ask,
        price_level_index: 0,
        price: 50.0,
        quantity: 30
      }

      assert {:error, :invalid_price_level_index_value} =
               Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it returns error if the 'price' param has invalid type",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :delete,
        side: :ask,
        price_level_index: 1,
        price: :foo,
        quantity: 30
      }

      assert {:error, :invalid_price_type} = Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it returns error if the 'quantity' param has invalid type",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :delete,
        side: :ask,
        price_level_index: 1,
        price: 100,
        quantity: :foo
      }

      assert {:error, :invalid_quantity_type} =
               Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it returns error if the 'price' equals 0 or lower",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :delete,
        side: :ask,
        price_level_index: 1,
        price: 0,
        quantity: 30
      }

      assert {:error, :invalid_price_value} = Exchange.send_instruction(exchange_pid, instruction)

      instruction = %{
        instruction: :delete,
        side: :ask,
        price_level_index: 1,
        price: -1,
        quantity: 30
      }

      assert {:error, :invalid_price_value} = Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it returns error if the 'quantity' equals 0 or lower",
         %{exchange_pid: exchange_pid} do
      instruction = %{
        instruction: :delete,
        side: :ask,
        price_level_index: 0,
        price: 10,
        quantity: 0
      }

      assert {:error, :invalid_quantity_value} =
               Exchange.send_instruction(exchange_pid, instruction)

      instruction = %{
        instruction: :delete,
        side: :ask,
        price_level_index: 0,
        price: 10,
        quantity: -1
      }

      assert {:error, :invalid_quantity_value} =
               Exchange.send_instruction(exchange_pid, instruction)
    end

    test "it returns error if server is not running",
         %{exchange_pid: exchange_pid} do
      Agent.stop(exchange_pid)

      instruction = %{
        instruction: :new,
        side: :bid,
        price_level_index: 1,
        price: 50.0,
        quantity: 30
      }

      assert {:error, :exchange_is_not_running} =
               Exchange.send_instruction(exchange_pid, instruction)
    end
  end
end
