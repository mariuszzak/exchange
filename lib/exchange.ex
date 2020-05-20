defmodule Exchange do
  @moduledoc """
  The module simulates a simplified model of an order book of a financial exchange
  ([https://en.wikipedia.org/wiki/Order_book_(trading)](https://en.wikipedia.org/wiki/Order_book_(trading)))
  """

  use Agent

  @spec start_link :: Agent.on_start()
  def start_link do
    initial_value = []
    Agent.start_link(fn -> initial_value end)
  end

  @typep validation_error ::
           :invalid_instruction_type
           | :invalid_side_type
           | :invalid_quantity_value
           | :invalid_quantity_type
           | :invalid_price_level_index_value
           | :invalid_price_level_index_type
           | :invalid_price_value
           | :invalid_price_type

  @spec send_instruction(exchange_pid :: pid(), event :: map()) ::
          :ok | {:error, validation_error() | :exchange_is_not_running}
  def send_instruction(exchange_pid, event) do
    with :ok <- validate_event(event),
         :ok <- validate_exchange_state(exchange_pid),
         :ok <- Agent.update(exchange_pid, &apply_event/1) do
      :ok
    end
  end

  defp validate_event(event) do
    with :ok <- validate_instruction(event),
         :ok <- validate_side(event),
         :ok <- validate_quantity(event),
         :ok <- validate_price_level_index(event),
         :ok <- validate_price(event) do
      :ok
    end
  end

  defp apply_event(state) do
    state
  end

  defp validate_instruction(%{instruction: instruction})
       when instruction in [:new, :update, :delete],
       do: :ok

  defp validate_instruction(_), do: {:error, :invalid_instruction_type}

  defp validate_side(%{side: side})
       when side in [:bid, :ask],
       do: :ok

  defp validate_side(_), do: {:error, :invalid_side_type}

  defp validate_quantity(%{quantity: quantity}) when is_integer(quantity) and quantity < 1,
    do: {:error, :invalid_quantity_value}

  defp validate_quantity(%{quantity: quantity}) when is_integer(quantity), do: :ok

  defp validate_quantity(_), do: {:error, :invalid_quantity_type}

  defp validate_price_level_index(%{price_level_index: price_level_index})
       when is_integer(price_level_index) and price_level_index < 1,
       do: {:error, :invalid_price_level_index_value}

  defp validate_price_level_index(%{price_level_index: price_level_index})
       when is_integer(price_level_index),
       do: :ok

  defp validate_price_level_index(_), do: {:error, :invalid_price_level_index_type}

  defp validate_price(%{price: price})
       when is_number(price) and price < 1,
       do: {:error, :invalid_price_value}

  defp validate_price(%{price: price})
       when is_number(price),
       do: :ok

  defp validate_price(_), do: {:error, :invalid_price_type}

  defp validate_exchange_state(exchange_pid) do
    case Process.alive?(exchange_pid) do
      true -> :ok
      false -> {:error, :exchange_is_not_running}
    end
  end
end
