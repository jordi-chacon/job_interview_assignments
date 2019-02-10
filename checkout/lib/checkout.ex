defmodule Checkout do
  @type item_code :: String.t()
  @type checkout :: %{
          required(:pricing_rules) => PricingRules.t(),
          required(:item_codes) => [item_code]
        }

  @spec new(PricingRules.t()) :: checkout
  def new(pricing_rules) do
    %{pricing_rules: pricing_rules, item_codes: []}
  end

  @spec scan(checkout, item_code) :: checkout
  def scan(checkout, item_code) do
    true = Map.has_key?(checkout.pricing_rules.item_prices, item_code)
    Map.update!(checkout, :item_codes, &[item_code | &1])
  end

  @spec total(checkout) :: String.t()
  def total(checkout) do
    checkout
    |> total_breakdown
    |> Enum.map(&Money.subtract(&1.price, &1.discount))
    |> Enum.reduce(Money.new(0), &Money.add(&1, &2))
    |> Money.to_string()
  end

  @spec formatted_breakdown(checkout) :: String.t()
  def formatted_breakdown(checkout) do
    checkout
    |> total_breakdown
    |> Enum.map(fn item ->
      line =
        String.pad_trailing(item.item_code, 7) <>
          (Money.to_string(item.price) |> String.pad_trailing(8))

      case Money.zero?(item.discount) do
        true -> line
        false -> line <> "(- #{Money.to_string(item.discount)})"
      end
    end)
    |> Kernel.++([
      String.pad_leading("", 26, "-"),
      "Total  #{total(checkout)}",
      ""
    ])
    |> Enum.join("\n")
  end

  @spec total_breakdown(checkout) :: [
          %{
            required(:item_code) => item_code,
            required(:price) => Money.t(),
            required(:discount) => Money.t(),
            required(:used_for_discount) => boolean()
          }
        ]
  defp total_breakdown(checkout) do
    checkout.item_codes
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {item_code, index} ->
      %{
        item_code: item_code,
        price: checkout.pricing_rules.item_prices[item_code],
        discount: Money.new(0),
        used_for_discount: false,
        index: index
      }
    end)
    |> apply_discounts(checkout)
  end

  defp apply_discounts(items, checkout) do
    Enum.reduce(checkout.pricing_rules.discounts, items, &apply_discount/2)
  end

  defp apply_discount(discount, items) do
    case is_discount_applicable?(items, discount) do
      true ->
        matching_items_indices = get_matching_items_indices(items, discount)
        items = flag_items_as_used_for_discount(items, matching_items_indices)

        case discount.price_reduction do
          {:matching_items, price_reduction} ->
            apply_price_reduction(
              items,
              matching_items_indices,
              price_reduction
            )

          {{:next_item, item_code}, price_reduction} ->
            index = get_next_item_index(items, item_code)
            apply_price_reduction(items, [index], price_reduction)
        end

      false ->
        items
    end
  end

  defp is_discount_applicable?(items, discount) do
    case get_matching_items_indices(items, discount) do
      nil ->
        false

      matching_items ->
        case discount.price_reduction do
          {:matching_items, _} ->
            true

          {{:next_item, item_code}, _} ->
            items
            |> flag_items_as_used_for_discount(matching_items)
            |> get_next_item_index(item_code)
            |> Kernel.!=(nil)
        end
    end
  end

  defp flag_items_as_used_for_discount(items, indices) do
    Enum.reduce(
      indices,
      items,
      fn index, acc ->
        List.update_at(acc, index, &Map.put(&1, :used_for_discount, true))
      end
    )
  end

  defp get_matching_items_indices(items, discount) do
    get_matching_items_indices(items, discount.match, [])
  end

  defp get_matching_items_indices(
         _items,
         items_left_to_match,
         matched_items_indices
       )
       when map_size(items_left_to_match) == 0 do
    matched_items_indices
  end

  defp get_matching_items_indices([], _items_left_to_match, _matched_items) do
    nil
  end

  defp get_matching_items_indices(
         [item | items],
         items_left_to_match,
         matched_items_indices
       ) do
    case not item.used_for_discount and
           Money.zero?(item.discount) and
           Map.has_key?(items_left_to_match, item.item_code) do
      false ->
        get_matching_items_indices(
          items,
          items_left_to_match,
          matched_items_indices
        )

      true ->
        new_items_left_to_match =
          items_left_to_match
          |> Map.update!(item.item_code, &(&1 - 1))
          |> delete_keys_with_value(0)

        get_matching_items_indices(
          items,
          new_items_left_to_match,
          [item.index | matched_items_indices]
        )
    end
  end

  defp delete_keys_with_value(%{} = m, value) do
    m
    |> Enum.filter(fn {_k, v} -> v != value end)
    |> Enum.into(%{})
  end

  defp get_next_item_index(items, item_code) do
    Enum.find_index(
      items,
      fn item ->
        item.item_code == item_code and
          not item.used_for_discount and
          Money.zero?(item.discount)
      end
    )
  end

  defp apply_price_reduction(items, indices, price_reduction) do
    Enum.reduce(
      indices,
      items,
      fn index, acc ->
        List.update_at(
          acc,
          index,
          fn item ->
            discount =
              case price_reduction do
                {:absolute, discount} -> discount
                {:relative, factor} -> Money.multiply(item.price, factor)
              end

            Map.put(item, :discount, discount)
          end
        )
      end
    )
  end
end
