defmodule Exchange do
  @moduledoc """
  The module simulates a simplified model of an order book of a financial exchange
  ([https://en.wikipedia.org/wiki/Order_book_(trading)](https://en.wikipedia.org/wiki/Order_book_(trading)))
  """

  use Agent

  @spec start_link :: Agent.on_start()
  def start_link do
    initial_value = []
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end
end
