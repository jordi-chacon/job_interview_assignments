defmodule CxOPricingRules do
  @behaviour PricingRules
  @moduledoc "Pricing rules set by the CxOs of our company"

  @impl PricingRules
  def get do
    %{
      item_prices: %{
        "GR1" => Money.new(311),
        "SR1" => Money.new(500),
        "CF1" => Money.new(1123)
      },
      discounts: [
        %{
          match: %{"GR1" => 1},
          price_reduction: {{:next_item, "GR1"}, {:relative, 1.0}}
        },
        %{
          match: %{"SR1" => 3},
          price_reduction: {:matching_items, {:absolute, Money.new(50)}}
        },
        %{
          match: %{"CF1" => 3},
          price_reduction: {:matching_items, {:relative, 1 / 3}}
        }
      ]
    }
  end
end
