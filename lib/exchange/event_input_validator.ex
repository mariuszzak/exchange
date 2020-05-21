defmodule Exchange.EventInputValidator do
  @moduledoc false

  alias Exchange.Event

  @type validation_error ::
          :invalid_instruction_type
          | :invalid_side_type
          | :invalid_quantity_value
          | :invalid_quantity_type
          | :invalid_price_level_index_value
          | :invalid_price_level_index_type
          | :invalid_price_value
          | :invalid_price_type

  @spec call(map()) :: {:ok, Event.t()} | validation_error()
  def call(event) do
    with :ok <- validate_instruction(event),
         :ok <- validate_side(event),
         :ok <- validate_quantity(event),
         :ok <- validate_price_level_index(event),
         :ok <- validate_price(event) do
      {:ok, struct(Event, event)}
    end
  end

  defp validate_instruction(%{instruction: instruction})
       when instruction in [:new, :update, :delete],
       do: :ok

  defp validate_instruction(_), do: {:error, :invalid_instruction_type}

  defp validate_side(%{side: side})
       when side in [:bid, :ask],
       do: :ok

  defp validate_side(_), do: {:error, :invalid_side_type}

  defp validate_quantity(%{instruction: :delete}), do: :ok

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

  defp validate_price(%{instruction: :delete}), do: :ok

  defp validate_price(%{price: price})
       when is_number(price) and price < 1,
       do: {:error, :invalid_price_value}

  defp validate_price(%{price: price})
       when is_number(price),
       do: :ok

  defp validate_price(_), do: {:error, :invalid_price_type}
end
