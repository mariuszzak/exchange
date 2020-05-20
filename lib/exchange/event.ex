defmodule Exchange.Event do
  @moduledoc false
  @struct_keys [:instruction, :side, :price_level_index, :price, :quantity]
  @enforce_keys @struct_keys
  defstruct @struct_keys

  @typep instruction :: :new | :update | :delete
  @typep side :: :bid | :ask
  @typep price_level_index :: pos_integer()
  @typep price :: number()
  @typep quantity :: pos_integer()

  @type t :: %__MODULE__{
          instruction: instruction(),
          side: side(),
          price_level_index: price_level_index(),
          price: price(),
          quantity: quantity()
        }
end
