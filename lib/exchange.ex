defmodule Exchange do
  @moduledoc """
  The module simulates a simplified model of an order book of a financial exchange
  ([https://en.wikipedia.org/wiki/Order_book_(trading)](https://en.wikipedia.org/wiki/Order_book_(trading)))
  """

  alias Exchange.{EventInputValidator, OrderBook}

  @spec start_link :: OrderBook.on_init()
  def start_link do
    OrderBook.init()
  end

  @spec send_instruction(exchange_pid :: pid(), event :: map()) ::
          :ok | {:error, EventInputValidator.validation_error()}
  def send_instruction(exchange_pid, event) do
    with {:ok, event} <- EventInputValidator.call(event),
         :ok <- OrderBook.apply_event(exchange_pid, event) do
      :ok
    end
  end

  @spec order_book(exchange_pid :: pid(), book_depth :: integer()) :: list(map())
  def order_book(exchange_pid, book_depth) do
    state = OrderBook.get(exchange_pid)

    # I believe it could be written it in a more performant way, but I assumed that
    # an order book does not need to display tons of data, so I focused on readability
    for price_level_index <- 1..book_depth do
      ask_side = Enum.at(state.ask, price_level_index - 1, %{})
      bid_side = Enum.at(state.bid, price_level_index - 1, %{})

      %{
        ask_price: Map.get(ask_side, :price, 0),
        ask_quantity: Map.get(ask_side, :quantity, 0),
        bid_price: Map.get(bid_side, :price, 0),
        bid_quantity: Map.get(bid_side, :quantity, 0)
      }
    end
  end
end
