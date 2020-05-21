defmodule Exchange.OrderBook do
  @moduledoc false

  alias Exchange.Event

  use Agent

  @enforce_keys [:bid, :ask]
  defstruct [:bid, :ask]

  @type t :: %__MODULE__{
          bid: list(),
          ask: list()
        }
  @type on_init :: Agent.on_start()

  @spec init :: on_init()
  def init do
    initial_value = %__MODULE__{bid: [], ask: []}
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
      insert_price_level(state, side, price_level_index, %{price: price, quantity: quantity})

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
        new_state =
          update_price_level(state, side, price_level_index, %{price: price, quantity: quantity})

        {:ok, new_state}
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
    new_state = delete_price_level(state, side, price_level_index)

    {:ok, new_state}
  end

  defp price_level(state, side, price_level_index) do
    state
    |> Map.get(side)
    |> Enum.at(price_level_index - 1)
  end

  defp insert_price_level(state, side, price_level_index, price_level) do
    Map.update!(state, side, &List.insert_at(&1, price_level_index - 1, price_level))
  end

  defp update_price_level(state, side, price_level_index, price_level) do
    Map.update!(state, side, &List.replace_at(&1, price_level_index - 1, price_level))
  end

  defp delete_price_level(state, side, price_level_index) do
    Map.update!(state, side, &List.delete_at(&1, price_level_index - 1))
  end

  defp update(exchange_pid, new_state) do
    Agent.update(exchange_pid, fn _state -> new_state end)
  end
end
