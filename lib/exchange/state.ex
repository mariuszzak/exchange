defmodule Exchange.State do
  @moduledoc false

  alias Exchange.Event

  @type t :: map()
  @type on_init :: Agent.on_start()

  @spec init :: on_init()
  def init do
    initial_value = %{}
    Agent.start_link(fn -> initial_value end)
  end

  @spec get(pid()) :: t()
  def get(exchange_pid) do
    Agent.get(exchange_pid, fn state -> state end)
  end

  @spec apply_event(pid, Event.t()) :: :ok | {:error, :price_level_does_not_exist}
  def apply_event(exchange_pid, event) do
    current_state = get(exchange_pid)

    case do_apply_event(current_state, event) do
      {:ok, new_state} ->
        update(exchange_pid, new_state)

      {:error, error} ->
        {:error, error}
    end
  end

  defp do_apply_event(
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

  defp do_apply_event(
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

  defp do_apply_event(
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

  defp update(exchange_pid, new_state) do
    Agent.update(exchange_pid, fn _state -> new_state end)
  end
end
