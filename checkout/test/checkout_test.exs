defmodule CheckoutTest do
  use ExUnit.Case

  test "CxOPricingRules, buy zero items" do
    checkout = checkout(CxOPricingRules, [])

    assert Checkout.total(checkout) == "£0.00"

    assert Checkout.formatted_breakdown(checkout) ==
             """
             --------------------------
             Total  £0.00
             """
  end

  test "CxOPricingRules, buy one GR1" do
    checkout = checkout(CxOPricingRules, ["GR1"])

    assert Checkout.total(checkout) == "£3.11"

    assert Checkout.formatted_breakdown(checkout) ==
             """
             GR1    £3.11   
             --------------------------
             Total  £3.11
             """
  end

  test "CxOPricingRules, buy two GR1, the second is free" do
    checkout = checkout(CxOPricingRules, ["GR1", "GR1"])

    assert Checkout.total(checkout) == "£3.11"

    assert Checkout.formatted_breakdown(checkout) ==
             """
             GR1    £3.11   
             GR1    £3.11   (- £3.11)
             --------------------------
             Total  £3.11
             """
  end

  test "CxOPricingRules, buy three GR1 items, the second is free" do
    checkout = checkout(CxOPricingRules, ["GR1", "GR1", "GR1"])

    assert Checkout.total(checkout) == "£6.22"

    assert Checkout.formatted_breakdown(checkout) ==
             """
             GR1    £3.11   
             GR1    £3.11   (- £3.11)
             GR1    £3.11   
             --------------------------
             Total  £6.22
             """
  end

  test "CxOPricingRules, buy three SR1, get a discount on all of them" do
    checkout = checkout(CxOPricingRules, ["SR1", "SR1", "SR1"])

    assert Checkout.total(checkout) == "£13.50"

    assert Checkout.formatted_breakdown(checkout) ==
             """
             SR1    £5.00   (- £0.50)
             SR1    £5.00   (- £0.50)
             SR1    £5.00   (- £0.50)
             --------------------------
             Total  £13.50
             """
  end

  test "CxOPricingRules, buy three CF1, get a discount on all of them" do
    checkout = checkout(CxOPricingRules, ["CF1", "CF1", "CF1"])

    assert Checkout.total(checkout) == "£22.47"

    assert Checkout.formatted_breakdown(checkout) ==
             """
             CF1    £11.23  (- £3.74)
             CF1    £11.23  (- £3.74)
             CF1    £11.23  (- £3.74)
             --------------------------
             Total  £22.47
             """
  end

  test "CxOPricingRules, buy many items" do
    checkout =
      checkout(
        CxOPricingRules,
        ["GR1", "SR1", "GR1", "GR1", "SR1", "CF1", "SR1", "CF1", "SR1", "SR1"]
      )

    assert Checkout.total(checkout) == "£52.18"

    assert Checkout.formatted_breakdown(checkout) ==
             """
             GR1    £3.11   
             SR1    £5.00   (- £0.50)
             GR1    £3.11   (- £3.11)
             GR1    £3.11   
             SR1    £5.00   (- £0.50)
             CF1    £11.23  
             SR1    £5.00   (- £0.50)
             CF1    £11.23  
             SR1    £5.00   
             SR1    £5.00   
             --------------------------
             Total  £52.18
             """
  end

  test "AltPricingRules, buy two GR1 and a SR1, get the second GR1 for free" do
    checkout = checkout(AltPricingRules, ["GR1", "GR1", "SR1"])

    assert Checkout.total(checkout) == "£6.00"

    assert Checkout.formatted_breakdown(checkout) ==
             """
             GR1    £2.00   
             GR1    £2.00   (- £2.00)
             SR1    £4.00   
             --------------------------
             Total  £6.00
             """
  end

  test "AltPricingRules, buy GR1 + SR1 + CF1, get a £1 discount on that CF1" do
    checkout = checkout(AltPricingRules, ["CF1", "GR1", "SR1"])

    assert Checkout.total(checkout) == "£11.00"

    assert Checkout.formatted_breakdown(checkout) ==
             """
             CF1    £6.00   (- £1.00)
             GR1    £2.00   
             SR1    £4.00   
             --------------------------
             Total  £11.00
             """
  end

  test "AltPricingRules, buy GR1 + GR1 + SR1 + CF1, two discounts are " <>
         "applicable but once the highest prio discount is applied, the second" <>
         "can't be applied anymore" do
    checkout = checkout(AltPricingRules, ["CF1", "GR1", "GR1", "SR1"])

    assert Checkout.total(checkout) == "£12.00"

    assert Checkout.formatted_breakdown(checkout) ==
             """
             CF1    £6.00   
             GR1    £2.00   
             GR1    £2.00   (- £2.00)
             SR1    £4.00   
             --------------------------
             Total  £12.00
             """
  end

  defp checkout(pricing_rules, item_codes) do
    Checkout.new(pricing_rules.get())
    |> scan(item_codes)
  end

  defp scan(checkout, item_codes) do
    Enum.reduce(
      item_codes,
      checkout,
      fn item_code, checkout -> Checkout.scan(checkout, item_code) end
    )
  end
end
