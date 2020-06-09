defmodule RGBMatrix.Layout.Xebow do
  alias RGBMatrix.KeyWithLED

  @keys [
    KeyWithLED.new(0, 0),
    KeyWithLED.new(0, 1),
    KeyWithLED.new(0, 2),
    KeyWithLED.new(0, 3),
    KeyWithLED.new(1, 0),
    KeyWithLED.new(1, 1),
    KeyWithLED.new(1, 2),
    KeyWithLED.new(1, 3),
    KeyWithLED.new(2, 0),
    KeyWithLED.new(2, 1),
    KeyWithLED.new(2, 2),
    KeyWithLED.new(2, 3)
  ]

  def keys do
    @keys
  end
end
