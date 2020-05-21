defmodule Exchange do
  @moduledoc """
  The module simulates a simplified model of an order book of a financial exchange
  ([https://en.wikipedia.org/wiki/Order_book_(trading)](https://en.wikipedia.org/wiki/Order_book_(trading)))
  """

  alias Exchange.{EventInputValidator, State}

  @spec start_link :: State.on_init()
  def start_link do
    State.init()
  end

  @type send_instruction_result ::
          :ok | {:error, EventInputValidator.validation_error() | :exchange_is_not_running}

  @spec send_instruction(exchange_pid :: pid(), event :: map()) :: send_instruction_result()
  def send_instruction(exchange_pid, event) do
    with {:ok, event} <- EventInputValidator.call(event),
         :ok <- check_exchange_server_state(exchange_pid),
         :ok <- State.apply_event(exchange_pid, event) do
      :ok
    end
  end

  defp check_exchange_server_state(exchange_pid) do
    case Process.alive?(exchange_pid) do
      true -> :ok
      false -> {:error, :exchange_is_not_running}
    end
  end

  @spec order_book(exchange_pid :: pid(), book_depth :: integer()) :: list(map())
  def order_book(exchange_pid, book_depth) do
    state = State.get(exchange_pid)

    for price_level_index <- 1..book_depth do
      ask_side = Map.get(state, {price_level_index, :ask}, %{})
      bid_side = Map.get(state, {price_level_index, :bid}, %{})

      %{
        ask_price: Map.get(ask_side, :price, 0),
        ask_quantity: Map.get(ask_side, :quantity, 0),
        bid_price: Map.get(bid_side, :price, 0),
        bid_quantity: Map.get(bid_side, :quantity, 0)
      }
    end
  end
end
