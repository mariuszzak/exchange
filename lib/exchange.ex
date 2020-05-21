defmodule Exchange do
  @moduledoc """
  The module simulates a simplified model of an order book of a financial exchange
  ([https://en.wikipedia.org/wiki/Order_book_(trading)](https://en.wikipedia.org/wiki/Order_book_(trading)))
  """

  use Agent

  alias Exchange.EventInputValidator

  @spec start_link :: Agent.on_start()
  def start_link do
    initial_value = %{}
    Agent.start_link(fn -> initial_value end)
  end

  @type send_instruction_result ::
          :ok | {:error, EventInputValidator.validation_error() | :exchange_is_not_running}

  @spec send_instruction(exchange_pid :: pid(), event :: map()) :: send_instruction_result()
  def send_instruction(exchange_pid, event) do
    with {:ok, event} <- EventInputValidator.call(event),
         :ok <- check_exchange_server_state(exchange_pid),
         {:ok, new_state} <- exchange_pid |> exchange_state() |> apply_event(event),
         :ok <- update_exchange_state(exchange_pid, new_state) do
      :ok
    end
  end

  defp check_exchange_server_state(exchange_pid) do
    case Process.alive?(exchange_pid) do
      true -> :ok
      false -> {:error, :exchange_is_not_running}
    end
  end

  defp apply_event(
         state,
         %{
           instruction: :new,
           price: price,
           price_level_index: price_level_index,
           quantity: quantity,
           side: side
         }
       ) do
    new_state =
      state
      |> maybe_shift_up_price_level(price_level_index, side)
      |> insert_price_level(side, price_level_index, %{price: price, quantity: quantity})

    {:ok, new_state}
  end

  defp apply_event(
         state,
         %{
           instruction: :update,
           price: price,
           price_level_index: price_level_index,
           quantity: quantity,
           side: side
         }
       ) do
    case price_level(state, side, price_level_index) do
      nil ->
        {:error, :price_level_does_not_exist}

      _ ->
        {:ok,
         update_price_level(state, side, price_level_index, %{price: price, quantity: quantity})}
    end
  end

  defp apply_event(
         state,
         %{
           instruction: :delete,
           side: side,
           price_level_index: price_level_index
         }
       ) do
    new_state =
      state
      |> delete_price_level(side, price_level_index)
      |> maybe_shift_down_price_level(price_level_index + 1, side)

    {:ok, new_state}
  end

  defp maybe_shift_up_price_level(state, price_level_index, side) do
    case price_level(state, side, price_level_index) do
      nil ->
        state

      price_level ->
        state
        |> maybe_shift_up_price_level(price_level_index + 1, side)
        |> insert_price_level(side, price_level_index + 1, price_level)
    end
  end

  defp maybe_shift_down_price_level(state, price_level_index, side) do
    case price_level(state, side, price_level_index) do
      nil ->
        state

      price_level ->
        state
        |> insert_price_level(side, price_level_index - 1, price_level)
        |> maybe_shift_down_price_level(price_level_index + 1, side)
        |> delete_price_level(side, price_level_index + 1)
    end
  end

  defp price_level(state, side, price_level_index) do
    Map.get(state, {price_level_index, side})
  end

  defp insert_price_level(state, side, price_level_index, price_level) do
    Map.put(state, {price_level_index, side}, price_level)
  end

  defp update_price_level(state, side, price_level_index, price_level) do
    Map.put(state, {price_level_index, side}, price_level)
  end

  defp delete_price_level(state, side, price_level_index) do
    Map.delete(state, {price_level_index, side})
  end

  @spec order_book(exchange_pid :: pid(), book_depth :: integer()) :: list(map())
  def order_book(exchange_pid, book_depth) do
    state = exchange_state(exchange_pid)

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

  defp exchange_state(exchange_pid) do
    Agent.get(exchange_pid, fn state -> state end)
  end

  defp update_exchange_state(exchange_pid, new_state) do
    Agent.update(exchange_pid, fn _state -> new_state end)
  end
end
