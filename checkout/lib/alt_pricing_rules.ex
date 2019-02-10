defmodule AltPricingRules do
  @behaviour PricingRules
  @moduledoc "Alternative pricing rules that the company is evaluating."

  @impl PricingRules
  def get do
    %{
      item_prices: %{
        "GR1" => Money.new(200),
        "SR1" => Money.new(400),
        "CF1" => Money.new(600)
      },
      discounts: [
        %{
          match: %{"GR1" => 1, "SR1" => 1},
          price_reduction: {{:next_item, "GR1"}, {:relative, 1.0}}
        },
        %{
          match: %{"GR1" => 1, "SR1" => 1},
          price_reduction: {{:next_item, "CF1"}, {:absolute, Money.new(100)}}
        }
      ]
    }
  end
end
