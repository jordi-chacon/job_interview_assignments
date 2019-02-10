defmodule PricingRules do
  @moduledoc """
  Behaviour that all PricingRules implementations should adopt.

  The person definining pricing rules should take the following into
  consideration:
  - the order in which `discounts` are specified indicates their priority,
  i.e. the first discount in the list will be the one that we attempt to apply
  first.
  - an item can be applied one discount at most.
  - an item can be used to apply one discount at most.
  - an item cannot be applied a discount and then be used to apply a separate
  discount, or viceversa.
  """

  @type item_code :: String.t()
  @type match_spec :: %{required(item_code) => amount :: integer}
  @type price_reduction :: {:absolute, Money.t()} | {:relative, float}
  @type discount :: %{
          required(:match) => match_spec,
          required(:price_reduction) =>
            {:matching_items | {:next_item, item_code}, price_reduction}
        }
  @type item_prices :: %{required(item_code) => price :: Money.t()}
  @type t :: %{
          required(:item_prices) => item_prices,
          required(:discounts) => [discount]
        }

  @callback get() :: t
end
