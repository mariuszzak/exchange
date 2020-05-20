defmodule Exchange do
  @moduledoc """
  The module simulates a simplified model of an order book of a financial exchange
  ([https://en.wikipedia.org/wiki/Order_book_(trading)](https://en.wikipedia.org/wiki/Order_book_(trading)))
  """

  use Agent

  alias Exchange.EventInputValidator

  @spec start_link :: Agent.on_start()
  def start_link do
    initial_value = []
    Agent.start_link(fn -> initial_value end)
  end

  @type send_instruction_result ::
          :ok | {:error, EventInputValidator.validation_error() | :exchange_is_not_running}

  @spec send_instruction(exchange_pid :: pid(), event :: map()) :: send_instruction_result()
  def send_instruction(exchange_pid, event) do
    with :ok <- EventInputValidator.call(event),
         :ok <- validate_exchange_state(exchange_pid),
         :ok <- Agent.update(exchange_pid, &apply_event/1) do
      :ok
    end
  end

  defp validate_exchange_state(exchange_pid) do
    case Process.alive?(exchange_pid) do
      true -> :ok
      false -> {:error, :exchange_is_not_running}
    end
  end

  defp apply_event(state) do
    state
  end
end
